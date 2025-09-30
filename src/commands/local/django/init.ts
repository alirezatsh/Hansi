import { Command, Flags } from '@oclif/core';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import inquirer from 'inquirer';
import {
  DjangoInitFlags,
  DjangoInitAnswers,
  DjangoScriptSearchResult,
  DjangoDockerOptions,
} from '../../../interfaces/django-interfaces.js';
import { DJANGO_SCRIPT_CANDIDATES , SCRIPT_SEARCH_TRY_LIMIT } from '../../../constants.js';
import { handleDockerForProject } from '../../../docker/django/run.js';

export default class DjangoInit extends Command {
  static description = 'Initialize a Django project with optional DB, Docker, and docker-compose';

  static flags = {
    db: Flags.string({ options: ['sqlite', 'postgres'], default: 'sqlite', description: 'Database type' }),
    dockerfile: Flags.boolean({ description: 'Create Dockerfile' }),
    dockercompose: Flags.boolean({ description: 'Create docker-compose.yml' }),
  };

  private exists(p: string): boolean {
    try {
      return fs.existsSync(p);
    } catch {
      return false;
    }
  }

  private searchScript(startDirs: string[], candidates: string[]): DjangoScriptSearchResult {
    const tried: string[] = [];
    for (const root of startDirs) {
      let dir = path.resolve(root);
      while (true) {
        for (const rel of candidates) {
          const candidate = path.join(dir, rel);
          tried.push(candidate);
          if (this.exists(candidate)) return { found: candidate, tried };
        }
        const parent = path.dirname(dir);
        if (parent === dir) break;
        dir = parent;
      }
    }
    return { tried };
  }

  private locateScript(): string {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);

    const startDirs = [__dirname, path.resolve(__dirname, '..'), process.cwd(), path.resolve(process.cwd(), '..')];

    const { found, tried } = this.searchScript(startDirs, DJANGO_SCRIPT_CANDIDATES);
    if (found) return found;

    const msg = ['setup_django_local.sh not found. Tried:', ...tried.slice(0, SCRIPT_SEARCH_TRY_LIMIT)].join('\n  ');
    this.error(msg);
    throw new Error(msg);
  }

  private async runScript(scriptPath: string, args: string[]): Promise<void> {
    const { spawn } = await import('child_process');
    return new Promise<void>((resolve, reject) => {
      const child = spawn('bash', [scriptPath, ...args], { stdio: 'inherit' });
      child.on('exit', (code: number) => {
        if (code === 0) resolve();
        else reject(new Error(`setup script exited with code ${code}`));
      });
      child.on('error', (err: Error) => reject(err));
    });
  }

  public async run(): Promise<void> {
    try {
      const parsed = await this.parse(DjangoInit);
      const flags = parsed.flags as unknown as DjangoInitFlags;

      const answers = await inquirer.prompt<DjangoInitAnswers>([
        { name: 'projectName', type: 'input', message: 'Enter project name:' },
      ]);

      const projectName = (answers.projectName || '').trim();
      if (!projectName) this.error('Project name is required.');

      const scriptPath = this.locateScript();

      const scriptArgs = [projectName, flags.db, flags.dockerfile ? 'yes' : 'no', flags.dockercompose ? 'yes' : 'no', 'no'];

      await this.runScript(scriptPath, scriptArgs);

      const projectDir = path.join(process.cwd(), projectName);

      const dockerOptions: DjangoDockerOptions = {
        projectName,
        projectDir,
        isSQLite: flags.db === 'sqlite',
        isPostgres: flags.db === 'postgres',
        dockerfile: !!flags.dockerfile,
        dockercompose: !!flags.dockercompose,
      };

      handleDockerForProject(dockerOptions);
    } catch (err: any) {
      this.error(err?.message ?? String(err));
    }
  }
}

import { Command, Flags } from '@oclif/core';
import { spawnSync } from 'child_process';
import path from 'path';
import fs from 'fs';
import os from 'os';
import { fileURLToPath } from 'url';
import inquirer from 'inquirer';

export default class DjangoInit extends Command {
  static description = 'Initialize a Django project with optional DB, Docker, and docker-compose';

  static flags = {
    db: Flags.string({ options: ['sqlite', 'postgres', 'cloud'], default: 'sqlite', description: 'Database type' }),
    dockerfile: Flags.boolean({ description: 'Create Dockerfile' }),
    dockercompose: Flags.boolean({ description: 'Create docker-compose.yml' }),
  };

  private findScriptInAncestors(startDirs: string[], relCandidates: string[]): { found?: string; tried: string[] } {
    const tried: string[] = [];

    for (const start of startDirs) {
      let dir = path.resolve(start);
      while (true) {
        for (const rel of relCandidates) {
          const candidate = path.join(dir, rel);
          tried.push(candidate);
          if (fs.existsSync(candidate)) {
            return { found: candidate, tried };
          }
        }
        const parent = path.dirname(dir);
        if (parent === dir) break;
        dir = parent;
      }
    }

    return { tried };
  }

  locateScript(): string {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);

    const rels = [
      path.join('src', 'scripts', 'django', 'setup_django_local.sh'),
      path.join('scripts', 'django', 'setup_django_local.sh'),
      path.join('dist', 'scripts', 'django', 'setup_django_local.sh'),
      path.join('src', 'scripts', 'setup_django_local.sh'),
      path.join('scripts', 'setup_django_local.sh'),
    ];

    const startDirs = [
      __dirname,
      path.resolve(__dirname, '..'),
      process.cwd(),
      path.resolve(process.cwd(), '..'),
    ];

    const { found, tried } = this.findScriptInAncestors(startDirs, rels);

    if (found) return found;

    const msg = [
      'setup_django_local.sh not found. I tried these locations (most likely the package was built without scripts copied to dist or files array):',
      ...tried.slice(0, 200), // limit to avoid huge output
    ].join('\n  ');
    this.error(msg);
    return '';
  }

  runCommand(command: string, args: string[], cwd?: string) {
    const res = spawnSync(command, args, { cwd: cwd || process.cwd(), stdio: 'inherit' });
    if (res.error) throw res.error;
    if (res.status !== 0) throw new Error(`${command} ${args.join(' ')} exited with code ${res.status}`);
  }

  async run() {
    const { flags } = await this.parse(DjangoInit);

    const answers = await inquirer.prompt([{ name: 'projectName', type: 'input', message: 'Enter project name:' }]);
    const projectName = answers.projectName.trim();
    if (!projectName) this.error('Project name is required.');

    const scriptPath = this.locateScript();

    const platform = os.platform();
    let osType = 'linux';
    if (platform === 'win32') osType = 'windows';
    else if (platform === 'darwin') osType = 'mac';

    const scriptArgs = [
      projectName,
      flags.db,
      flags.dockerfile ? 'y' : 'n',
      flags.dockercompose ? 'y' : 'n',
      'n',
      osType,
    ];

    this.runCommand('bash', [scriptPath, ...scriptArgs]);

    const projectDir = path.join(process.cwd(), projectName);

    const isPostgres = flags.db === 'postgres';
    const isSQLite = flags.db === 'sqlite';

    if (flags.dockerfile && fs.existsSync(path.join(projectDir, 'Dockerfile'))) {
      if (isSQLite && !flags.dockercompose) {
        this.log('Building Docker image...');
        this.runCommand('docker', ['build', '-t', projectName, '.'], projectDir);
        try { this.runCommand('docker', ['rm', '-f', projectName]); } catch {}
        this.log('Running Docker container...');
        this.runCommand('docker', ['run', '-d', '--name', projectName, '-p', '8000:8000', projectName]);
      } else {
        this.log('Dockerfile copied (execution skipped).');
      }
    }

    if (flags.dockercompose && isPostgres && fs.existsSync(path.join(projectDir, 'docker-compose.yml'))) {
      this.log('docker-compose.yml copied (execution skipped).');
    }

    this.log(`Project '${projectName}' created successfully!`);
    this.log('Check guide.txt for more information.');
  }
}

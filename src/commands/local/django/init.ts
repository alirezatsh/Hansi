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

  locateScriptCandidates(): string[] {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    return [
      path.join(process.cwd(), 'src', 'scripts', 'django', 'setup_django_local.sh'),
      path.join(process.cwd(), 'scripts', 'django', 'setup_django_local.sh'),
      path.join(__dirname, '..', '..', 'src', 'scripts', 'django', 'setup_django_local.sh'),
      path.join(__dirname, '..', '..', 'scripts', 'django', 'setup_django_local.sh'),
    ];
  }

  findScript(): string {
    const candidates = this.locateScriptCandidates();
    for (const c of candidates) {
      if (fs.existsSync(c)) return c;
    }
    this.error('setup_django_local.sh not found in expected locations.');
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

    const scriptPath = this.findScript();

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

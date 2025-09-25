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
    db: Flags.string({ char: 'd', options: ['sqlite', 'postgres', 'cloud'], default: 'sqlite' }),
    dockerfile: Flags.boolean({ char: 'f', description: 'Create Dockerfile and build/run container' }),
    dockerCompose: Flags.boolean({ char: 'c', description: 'Create docker-compose.yml and run docker-compose up' }),
  };

  locateScriptCandidates(): string[] {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const candidates = [
      path.join(process.cwd(), 'src', 'scripts', 'django', 'setup_django_local.sh'),
      path.join(process.cwd(), 'scripts', 'django', 'setup_django_local.sh'),
      path.join(__dirname, '..', '..', 'src', 'scripts', 'django', 'setup_django_local.sh'),
      path.join(__dirname, '..', '..', 'scripts', 'django', 'setup_django_local.sh'),
      path.join(__dirname, '..', '..', '..', 'src', 'scripts', 'django', 'setup_django_local.sh'),
    ];
    return candidates;
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
    const res = spawnSync(command, args, { cwd: cwd || process.cwd(), stdio: 'inherit', shell: false });
    if (res.error) throw res.error;
    if (res.status !== 0) throw new Error(`${command} ${args.join(' ')} exited with code ${res.status}`);
    return res;
  }

  async run() {
    const { flags } = await this.parse(DjangoInit);

    const questions: any[] = [{ name: 'projectName', type: 'input', message: 'Enter project name:' }];

    if (flags.db === 'cloud') {
      questions.push({ name: 'cloudDbUrl', type: 'input', message: 'Enter cloud DB URL (optional):' });
    }

    const answers = await inquirer.prompt(questions);
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
      flags.dockerCompose ? 'y' : 'n',
      'n',
      osType,
      answers.cloudDbUrl || '',
    ];

    try {
      this.log(`Running scaffold script: ${scriptPath}`);
      this.runCommand('bash', [scriptPath, ...scriptArgs]);

      const projectDir = path.join(process.cwd(), projectName);

      if (flags.dockerfile) {
        if (!fs.existsSync(path.join(projectDir, 'Dockerfile'))) {
          this.warn('Dockerfile not found in project root. Skipping docker build/run.');
        } else {
          this.log('Building Docker image...');
          this.runCommand('docker', ['build', '-t', projectName, '.'], projectDir);
          try {
            this.runCommand('docker', ['rm', '-f', projectName]);
          } catch { }
          this.log('Running Docker container...');
          this.runCommand('docker', ['run', '-d', '--name', projectName, '-p', '8000:8000', projectName]);
          this.log(`Container '${projectName}' started and mapped to host port 8000.`);
        }
      }

      if (flags.dockerCompose) {
        if (!fs.existsSync(path.join(projectDir, 'docker-compose.yml'))) {
          this.warn('docker-compose.yml not found in project root. Skipping docker-compose up.');
        } else {
          this.log('Running docker-compose up -d ...');
          this.runCommand('docker-compose', ['up', '-d'], projectDir);
          this.log('docker-compose services are up.');
        }
      }

      this.log(`Project '${projectName}' created successfully!`);
    } catch (err: any) {
      this.error('Failed: ' + (err.message || String(err)));
    }
  }
}

import {Command, Flags} from '@oclif/core';
import {execSync} from 'child_process';
import path from 'path';
import inquirer from 'inquirer';
import fs from 'fs';

export default class DjangoInit extends Command {
  static description = 'Initialize a Django project with optional DB, Docker, and superuser setup';

  static flags = {
    db: Flags.string({char: 'd', options: ['sqlite', 'postgres', 'cloud'], default: 'sqlite'}),
    dockerfile: Flags.boolean({char: 'f'}),
    dockerCompose: Flags.boolean({char: 'c'}),
    superuser: Flags.boolean({char: 's'}),
  };

  findScript(relativePath: string): string {
    const scriptPath = path.resolve(process.cwd(), relativePath);
    if (!fs.existsSync(scriptPath)) {
      this.error(`Script not found: ${relativePath}`);
    }
    return scriptPath;
  }

  async run() {
    const {flags} = await this.parse(DjangoInit);

    const questions: any[] = [{name: 'projectName', type: 'input', message: 'Enter project name:'}];

    if (flags.db === 'cloud') {
      questions.push({name: 'cloudDbUrl', type: 'input', message: 'Cloud DB URL:'});
    }

    const answers = await inquirer.prompt(questions);

    const scriptPath = this.findScript(path.join('src', 'scripts', 'django', 'setup_django_local.sh'));

    const args = [
      answers.projectName,
      flags.db,
      flags.dockerfile ? 'y' : 'n',
      flags.dockerCompose ? 'y' : 'n',
      flags.superuser ? 'y' : 'n',
      '',
      '',
      '',
      answers.cloudDbUrl || '',
    ];

    try {
      execSync(`${scriptPath} ${args.map(a => `"${a}"`).join(' ')}`, {stdio: 'inherit', shell: '/bin/bash'});
      this.log(`Project '${answers.projectName}' created successfully!`);
    } catch (err: any) {
      this.error('Failed to create project: ' + err.message);
    }
  }
}

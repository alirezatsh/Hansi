import { spawnSync } from 'child_process';
import path from 'path';
import fs from 'fs';
import { DJANGO_PORT } from '../../constants.js';
import type { DjangoDockerOptions } from '../../interfaces/django-interfaces.js';

function exists(p: string): boolean {
  try {
    return fs.existsSync(p);
  } catch {
    return false;
  }
}

function runSync(command: string, args: string[], cwd?: string): void {
  const res = spawnSync(command, args, { cwd: cwd || process.cwd(), stdio: 'inherit' });
  if (res.error) throw res.error;
  if (res.status !== 0) throw new Error(`${command} ${args.join(' ')} exited with code ${res.status}`);
}

function waitForContainer(name: string, retries = 10, intervalMs = 500): void {
  for (let i = 0; i < retries; i++) {
    const res = spawnSync('docker', ['ps', '--filter', `name=^${name}$`, '--format', '{{.Names}}'], { encoding: 'utf-8' });
    if (res.stdout.trim() === name) return;
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, intervalMs);
  }
  throw new Error(`Docker container "${name}" did not start in time`);
}

export function handleDockerForProject(options: DjangoDockerOptions): void {
  const dockerfilePath = path.join(options.projectDir, 'Dockerfile');

  if (!options.dockerfile || !exists(dockerfilePath)) return;
  if (!options.isSQLite || options.dockercompose) return;

  runSync('docker', ['build', '-t', options.projectName, '.'], options.projectDir);

  runSync('docker', ['run', '-d', '--name', options.projectName, '-p', DJANGO_PORT, options.projectName]);

  waitForContainer(options.projectName);
}

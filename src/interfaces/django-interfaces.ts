export interface DjangoInitFlags {
  db: 'sqlite' | 'postgres';
  dockerfile: boolean;
  dockercompose: boolean;
}

export interface DjangoInitAnswers {
  projectName: string;
}

export interface DjangoScriptSearchResult {
  found?: string;
  tried: string[];
}

export interface DjangoDockerOptions {
  projectName: string;
  projectDir: string;
  isSQLite: boolean;
  isPostgres: boolean;
  dockerfile: boolean;
  dockercompose: boolean;
}

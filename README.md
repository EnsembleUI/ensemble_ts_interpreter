# how to use the typescript parser locally to convert typescirpt code to AST

1. Install the typescript-estree parser from here - https://www.npmjs.com/package/@typescript-eslint/typescript-estree 
2. Install ts-node for executing typescript command line - https://www.npmjs.com/package/ts-node#installation
3. Use the following as an example

```
import { parse } from '@typescript-eslint/typescript-estree';
import { readFileSync } from 'fs';

//read the file containing just typescript (or javascript) from the file system and convert to ast
const code = readFileSync('propsthroughquotes.ts', 'utf-8');
const ast = parse(code, {
  loc: false,
  range: false,
  tokens:false,
  sourceType: 'module'
});
console.log(JSON.stringify(ast));
```
The propsthroughquotes.ts is below for reference. It can be any javascript or typescipt code block
```
ensembleStore.session.login.cookie = response.headers['Set-Cookie'].split(';')[0]
```


import '@angular/compiler';

import { render } from '@keycloakify/angular-email';
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { TailwindComponent } from './tailwind.component';

render({
  component: TailwindComponent,
  selector: 'app-root',
  props: { preview: `Read Alex's review` },
  options: {
    pretty: true,
    cssFilePaths: [resolve(import.meta.dirname, '../styles.css')],
    tailwindConfig: resolve(import.meta.dirname, '../tailwind.config.js'),
  },
}).then((html) => {
  writeFileSync(resolve(import.meta.dirname, 'test.html'), html);
});

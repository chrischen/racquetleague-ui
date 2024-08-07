/* TypeScript file generated from LangSwitch.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as LangSwitchJS from './LangSwitch.re.mjs';

export type LocaleButton_t = { readonly locale: string; readonly display: string };

export type LocaleButton_props<locale,path,active> = {
  readonly locale: locale; 
  readonly path: path; 
  readonly active: active
};

export type props = {};

export const LocaleButton_make: React.ComponentType<{
  readonly locale: LocaleButton_t; 
  readonly path: string; 
  readonly active: boolean
}> = LangSwitchJS.LocaleButton.make as any;

export const make: React.ComponentType<{}> = LangSwitchJS.make as any;

export const $$default: React.ComponentType<{}> = LangSwitchJS.default as any;

export default $$default;

export const LocaleButton: { make: React.ComponentType<{
  readonly locale: LocaleButton_t; 
  readonly path: string; 
  readonly active: boolean
}> } = LangSwitchJS.LocaleButton as any;

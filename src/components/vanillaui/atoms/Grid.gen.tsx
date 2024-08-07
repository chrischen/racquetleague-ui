/* TypeScript file generated from Grid.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as GridJS from './Grid.re.mjs';

export type props<cols,rows,className,children> = {
  readonly cols?: cols; 
  readonly rows?: rows; 
  readonly className?: className; 
  readonly children: children
};

export const make: React.ComponentType<{
  readonly cols?: number; 
  readonly rows?: number; 
  readonly className?: string; 
  readonly children: React.ReactNode
}> = GridJS.make as any;

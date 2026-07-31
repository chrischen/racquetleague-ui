import { vi } from "vitest";

// this file is ran right after the test framework is setup for some test file.
(globalThis as any).IS_REACT_ACT_ENVIRONMENT = true;

// logger import on graphql app.js

// Needed to process node imports without file extensions
import "extensionless/register";
import '@testing-library/jest-dom/vitest';

global.ResizeObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
}));

// Set methods the app relies on (and gates browsers on via `Rating.isSupported`)
// landed in Node 22; polyfill them so tests can run on Node 20.
type SetLike<T> = { has(value: T): boolean };
if (typeof (Set.prototype as any).intersection !== "function") {
  (Set.prototype as any).intersection = function <T>(this: Set<T>, other: SetLike<T>) {
    const out = new Set<T>();
    this.forEach((v) => {
      if (other.has(v)) out.add(v);
    });
    return out;
  };
}
if (typeof (Set.prototype as any).difference !== "function") {
  (Set.prototype as any).difference = function <T>(this: Set<T>, other: SetLike<T>) {
    const out = new Set<T>();
    this.forEach((v) => {
      if (!other.has(v)) out.add(v);
    });
    return out;
  };
}
// import "raf/polyfill";
// import { configure } from 'enzyme';
// import Adapter from 'enzyme-adapter-react-16';

// configure({ adapter: new Adapter() });

// require('jest-fetch-mock').enableMocks();

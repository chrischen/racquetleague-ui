// Small helpers shared by the story files.

/** The value, or an error naming what the story expected to find, in place of a `!` assertion. */
export function must<T>(value: T | null | undefined, what: string): T {
  if (value == null) throw new Error(`Story setup: ${what} not found`);
  return value;
}

/** A promise that never settles, to hold a mocked request in flight for a loading state. */
export function pending<T = never>(): Promise<T> {
  return new Promise<T>(() => undefined);
}

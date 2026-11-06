export function greeting(name) {
  const trimmed = name?.trim();
  return trimmed ? `Hello, ${trimmed}!` : "Hello, world!";
}

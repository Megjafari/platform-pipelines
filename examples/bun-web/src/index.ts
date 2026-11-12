import { greeting } from "./greeting";

const heading = document.querySelector("h1");
if (heading) {
  heading.textContent = greeting();
}

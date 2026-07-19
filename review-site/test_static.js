#!/usr/bin/env node
"use strict";

// Small dependency-free smoke test for the static review site.
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const root = __dirname;
const workspace = path.resolve(root, "..");
const html = fs.readFileSync(path.join(root, "index.html"), "utf8");
const css = fs.readFileSync(path.join(root, "styles.css"), "utf8");
const app = fs.readFileSync(path.join(root, "app.js"), "utf8");

function expect(condition, message) {
  if (!condition) throw new Error(message);
}

expect(html.includes('href="styles.css"') && html.includes('src="app.js"'), "HTML must load the local CSS and JS assets");
expect(["C1", "C2", "C3", "C4", "C5", "C6"].every(chapter => app.includes(`short: "${chapter}"`)), "C1–C6 chapters are incomplete");
expect((app.match(/required: true/g) || []).length >= 14, "The C-stage required-task checklist is unexpectedly incomplete");
expect(["renderArchitecture", "renderCommands", "renderQuiz", "renderPpt"].every(view => app.includes(`function ${view}`)), "A required view is missing");
expect(app.includes("vscode://vscode-remote/wsl+"), "VS Code WSL Remote deep links are missing");
expect(app.includes("一生一芯项目架构") && app.includes("NPC 微架构") && app.includes("Makefile 调用时序"), "One of the three required diagrams is missing");
expect(!app.includes("vsrc_pip"), "The site must point to the current npc/vsrc RTL, not the deprecated vsrc_pip path");
expect(css.includes(".diagram-panel") && css.includes(".quiz-dashboard"), "Diagram or quiz styling is missing");

const quizRenderer = app.indexOf("function renderQuiz()");
const quizControls = app.indexOf("${quizControls(quiz)}", quizRenderer);
const quizQuestions = app.indexOf("${questions.map", quizRenderer);
expect(quizControls !== -1 && quizControls < quizQuestions, "Quiz controls must be visible before the questions");
expect(app.includes('href="#answer-deck"') && app.includes('id="answer-deck"'), "The direct answer-deck entry point is missing");
expect(css.includes(".option.locked"), "Locked quiz options need an explicit disabled state");

const sourceLinks = [...app.matchAll(/\["([^"\n]+\/[^"\n]+)",\s*\d+,\s*"[^"\n]+"\]/g)].map(match => match[1]);
const missingSources = sourceLinks.filter(source => !fs.existsSync(path.join(workspace, source)));
expect(missingSources.length === 0, `A VS Code source link does not exist: ${missingSources.join(", ")}`);

function runQuizFlow() {
  const listeners = {};
  const storage = new Map();
  const makeElement = () => {
    const classes = new Set();
    return {
      style: {}, dataset: {}, value: "", textContent: "", innerHTML: "",
      classList: {
        add: name => classes.add(name), remove: name => classes.delete(name), contains: name => classes.has(name),
        toggle: (name, force) => { const enabled = force === undefined ? !classes.has(name) : Boolean(force); enabled ? classes.add(name) : classes.delete(name); return enabled; }
      },
      addEventListener() {}, focus() {}, close() {}, querySelector: () => makeElement()
    };
  };
  const appElement = makeElement();
  const dialogClose = makeElement();
  const detailDialog = makeElement();
  detailDialog.querySelector = () => dialogClose;
  const elements = new Map([
    ["#app", appElement], ["#workspace-root", makeElement()], ["#wsl-distro", makeElement()],
    ["#detail-dialog", detailDialog], ["#dialog-content", makeElement()], ["#toast", makeElement()],
    ["#view-kicker", makeElement()], ["#view-title", makeElement()], ["#sidebar-progress", makeElement()],
    ["#sidebar-progress-bar", makeElement()], ["#reset-progress", makeElement()], ["#toggle-focus", makeElement()],
    ["#toggle-mobile-nav", makeElement()], [".sidebar", makeElement()], [".quiz-meta span:last-child", makeElement()]
  ]);
  const document = {
    body: makeElement(),
    querySelector: selector => elements.get(selector) || makeElement(),
    querySelectorAll: () => [],
    addEventListener: (type, listener) => { listeners[type] = listener; }
  };
  const window = {
    location: { search: "" }, clearTimeout() {}, setTimeout() { return 1; }, clearInterval() {}, setInterval() { return 1; },
    prompt() {}, confirm() { return true; }
  };
  const localStorage = { getItem: key => storage.get(key) || null, setItem: (key, value) => storage.set(key, String(value)) };
  vm.runInNewContext(app, { document, window, localStorage, navigator: {}, URLSearchParams, console }, { filename: "app.js" });

  const target = matches => ({ closest: selector => matches[selector] || null });
  listeners.click({ target: target({ "[data-view]": { dataset: { view: "quiz" } } }) });
  expect(appElement.innerHTML.indexOf("data-quiz-start") < appElement.innerHTML.indexOf("data-quiz-question"), "Start control must precede quiz options");

  listeners.click({ target: target({ "[data-quiz-start]": {} }) });
  expect(!appElement.innerHTML.includes(" disabled"), "Quiz options must unlock after starting");

  const quiz = JSON.parse(storage.get("ysyx-review-quiz-v1"));
  const option = { dataset: { quizQuestion: quiz.questionIds[0] }, value: "0", closest: selector => selector === "[data-quiz-question]" ? option : null };
  listeners.change({ target: option });
  expect(JSON.parse(storage.get("ysyx-review-quiz-v1")).answers[quiz.questionIds[0]] === 0, "Selecting an option must persist the answer");

  listeners.click({ target: target({ "[data-quiz-submit]": {} }) });
  expect(JSON.parse(storage.get("ysyx-review-quiz-v1")).submitted, "Submitting the quiz must persist the result");
  expect(appElement.innerHTML.includes("正确答案：") && appElement.innerHTML.includes("解析"), "Submitting must show answers and explanations");
}

runQuizFlow();

console.log("review-site static smoke test passed");

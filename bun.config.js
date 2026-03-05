import path from 'path';
import fs from 'fs';

const preactCompat = {
  name: "preact-compat",
  setup(build) {
    build.onResolve({ filter: /^react(-dom)?(\/.*)?$/ }, (args) => {
      const mapping = {
        "react/jsx-runtime": "preact/jsx-runtime",
        "react-dom/client": "preact/compat/client",
      }
      const target = mapping[args.path] ?? "preact/compat"
      return { path: import.meta.resolveSync(target) }
    })
  },
}

const config = {
  sourcemap: "external",
  entrypoints: ["app/javascript/application.ts"],
  outdir: path.join(process.cwd(), "app/assets/builds"),
  splitting: true,
  format: "esm",
  publicPath: "/assets/",
  naming: {
    entry: "[name].[ext]",
    chunk: "[name]-[hash].digested.[ext]",
  },
  plugins: [preactCompat],
};

const build = async (config) => {
  const result = await Bun.build(config);

  if (!result.success) {
    if (process.argv.includes('--watch')) {
      console.error("Build failed");
      for (const message of result.logs) {
        console.error(message);
      }
      return;
    } else {
      throw new AggregateError(result.logs, "Build failed");
    }
  }
};

(async () => {
  await build(config);

  if (process.argv.includes('--watch')) {
    fs.watch(path.join(process.cwd(), "app/javascript"), { recursive: true }, (eventType, filename) => {
      console.log(`File changed: ${filename}. Rebuilding...`);
      build(config);
    });
  } else {
    process.exit(0);
  }
})();

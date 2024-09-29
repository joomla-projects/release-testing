import { defineConfig } from 'cypress-image-diff-html-report'

export default defineConfig({
  // config options
  reportJsonDir: '../output/visual-regression-diff/cypress-image-diff-html-report',
  outputDir: '../output/visual-regression-diff/cypress-image-diff-html-report',
  inlineAssets: false,
  autoOpen: false,
})

/**
 * Creates a custom error message string that includes context information, the error message, and the last logged steps.
 *
 * @param {Error} error - The error object containing the error message.
 * @param {string[]} steps - An array of strings representing the steps logged before the error occurred.
 * @param {Object} currentTest - An object containing information about the test context.
 * @param {Object} currentSpec - An object containing information about the spec context.
 * @param {string} currentTest.title - The title of the test.
 * @param {string} currentSpec.relative - The relative path of the spec file.
 * @returns {string} - A formatted error message string.
 */
const createCustomErrorMessage = (error, steps, currentTest, currentSpec) => {
    let lastSteps = "Last logged steps:\n"
    steps.map((step, index) => {
      lastSteps += `${index + 1}. ${step}\n`
    })
  const messageArr = [
      `Context: ${currentSpec.relative}`,
      `Test: ${currentTest.title}`,
      `----------`,
      `${error.message}`,
      `\n${lastSteps}`,
    ]
    return messageArr.join('\n')
}

export { createCustomErrorMessage }
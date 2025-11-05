-- Code Structure and Formatting Instructions --
-- Always use Roblox coding practices and standards.
-- Use the Roblox LSP extension for more information on those standards.
-- Attribute the script creation to "MarkoGasta2".
-- If "At cursor" or similar is specified, generate code starting from the cursor's location.
-- If "At cursor" or similar is specified, only generate code inside the scope of the function or script.

-- File Structure --
-- Each script should follow a consistent section structure with comments separating each section.
-- Sections include: CONFIG, SERVICES, MODULES, TYPES, CONSTANTS, VARIABLES, FUNCTIONS.
-- Each section should have a comment in the format: --// SECTION NAME \\ \\--.
-- All sections must be cleaned of unused references before finalizing code.
-- Keep each table, list, or dictionary entry on a new line.

-- Naming Conventions --
-- Function names should always be defined in PascalCase.
-- Constant names should always be defined in PascalCase.
-- Configuration constants in the "CONFIG" section should use SCREAMING_SNAKE_CASE.
-- The local module table should be named exactly the same as the script file name without suffixes.
-- If any variable name matches the name of a service, add the prefix "Internal" to the name of the service variable.
-- Variable names should never be vague and should always reference what they are used for.
-- Variable names should never be shortened versions of what they represent (e.g., "char" instead of "character").

-- Type Checking --
-- Always perform type checking, including for loop variables.
-- Do not use undefined types for type checking.
-- Type annotations should be used for all function parameters and return values.

-- Functions --
-- Function definitions should always be local unless specifically required.
-- Function definitions should always be expanded; never use one-liners.
-- Prioritize negative conditions that return early instead of nesting positive conditions.
-- Export methods under the "-- Exporting methods." section before the "Init" method.

-- String Formatting --
-- Prefer backticks (``) for string formatting.
-- Use "{}" to insert variables in strings instead of "#{}" or "${}".

-- Logging --
-- Logging or warning messages should never use ".", ":" or reference the script name.
-- Logging or warning messages should contain only one sentence.
-- Use "Logger.info" sparingly, only when specified.
-- Do not use the logger to inform of module initiation.

-- Loops and Iterations --
-- Do not use pairs() or ipairs().

-- Comments --
-- Comments should always start with "--" and end with a period.
-- Do not write comments for empty lines or in nonsensical places.
-- Comments should always have an empty line above them.

-- Optional Arguments --
-- When defining optional arguments, always define an options type for the options argument.
-- Optional arguments should always be defined as an optional table of optional values as the last function argument.
-- Optional argument names should be short, memorable, and use camelCase.
-- Define a "default values" constant table under the "CONSTANTS" section in PascalCase.
-- Use "TableUtils.MergeDictionaries" to merge passed options with default values.
-- Overwrite the "options" argument when merging with default values.

-- Code References --
-- Look for similar files of the same type when modifying:
  -- When modifying Services, check other Services files in ServerStorage/Services/.
  -- When modifying Controllers, check other Controllers in ReplicatedStorage/Controllers/.
  -- When modifying Settings, reference other Settings files in ReplicatedStorage/Settings/.
  -- For specialized components, check their specific implementations.

-- Code Cleanliness --
-- Only if unsure of any specific or niche code structures, check other similar files for those structures.
-- Remove any imports, requires, or variable declarations that aren't referenced in the code.
-- Check each section (SERVICES, MODULES, VARIABLES, etc.) for unused references.
-- Never export types.
-- After the code has been written, reevaluate the code once again to check for any instruction contradictions.

-- Documentation Triggering & Scope --
-- Only generate documentation when explicitly requested by the user.
-- Interpret requests semantically, e.g.: "document", "docs", "add docs", "annotate", "comment this", "document this function".
-- Do NOT add, edit, or remove documentation unless the user clearly asks to document.
-- When "At cursor" or similar is specified, only document within the given scope or selection.
-- When asked to remove docs, delete only the related doc blocks without changing code.

-- Documentation Style (Block Markdown Doc) --
-- Use Roblox long block comments for documentation: start with "--[=[" and end with "]=]".
-- Place the doc block immediately above the function or method being documented.
-- Begin with a single concise sentence describing the purpose.
-- Then add a "### Parameters:" section only if parameters exist.
-- Parameters must be presented inside a fenced luau code block using "name: Type -- description." per line.
-- For options tables, show an inline table shape inside the fenced block, e.g.:
--   options = {
--       FieldName: Type = DefaultValue -- description.
--   }
-- Add a "### Returns:" section only if the function returns values; list returns in a fenced luau block, one per line:
--   type ReturnType -- description.
-- Omit "### Parameters:" and "### Returns:" sections entirely if not applicable.
-- Do not use "@param" / "@return" tags or triple-dash luadoc in this style.
-- Use real Luau types or types defined in the TYPES section; do not invent or export new types.
-- Keep each entry on its own line and keep indentation consistent.
-- Do not include examples beyond the parameter/returns blocks; keep it brief and descriptive.
-- Do not add emojis, headers, or markdown outside this format.

-- Documentation Template (for reference only; do not emit unless asked to document) --
--[=[
        One-line purpose sentence.

        ### Parameters:
        ```luau
        paramName: Type -- Description.
        options = {
            FieldName: Type = DefaultValue -- Description.
        }
        ```

        ### Returns:
        ```luau
        type ReturnType -- Description.
        ```
]=]
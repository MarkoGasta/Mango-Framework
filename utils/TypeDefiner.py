import os
from tqdm import tqdm

# Configuration dictionary
project_root = 'X:\\Projects\\Roblox Repos\\Mango Framework v2\\'
config = {
    project_root + 'src\\ReplicatedStorage\\MangoClient\\Types.luau': [
        project_root + 'src\\ReplicatedStorage\\Controllers',
        project_root + 'src\\ReplicatedStorage\\Settings',
        project_root + 'src\\ReplicatedStorage\\Resources',
    ],
    project_root + 'src\\ServerStorage\\MangoServer\\Types.luau': [
        project_root + 'src\\ServerStorage\\Services',
        project_root + 'src\\ServerStorage\\Resources',
        project_root + 'src\\ReplicatedStorage\\Settings',
        project_root + 'src\\ReplicatedStorage\\Resources\\Shared',
    ],
}

def gather_modules(input_paths, output_path):
    """
    Gather all .luau files and directories treated as modules from the input paths,
    excluding the output path itself. Ignores directories that start with '_'.
    """
    modules = []

    def process_path(path, top_level=False):
        items = os.listdir(path)
        module_found = False

        for item in items:
            module_found = False
            full_path = os.path.join(path, item)

            # Ignore directories that start with '_'
            if os.path.isdir(full_path) and item.startswith("_"):
                continue

            if os.path.isfile(full_path):
                if item.endswith('.luau') and (not top_level or item != 'init.luau'):
                    if full_path != output_path:
                        modules.append(full_path)
            elif os.path.isdir(full_path):
                if 'init.luau' in os.listdir(full_path):
                    if full_path != output_path:
                        modules.append(full_path)
                    module_found = True
                elif not module_found:
                    process_path(full_path)
    
    for path in input_paths:
        process_path(path, top_level=True)
    
    return modules

def write_types_file(output_path, modules, input_paths):
    """
    Write the Types.luau file with the gathered module data.
    """
    with open(output_path, 'w') as file:
        file.write("\n".join(f"-- Indexed from: {path}" for path in input_paths) + "\n\n")

        module_names = [os.path.basename(m).replace(".luau", "") for m in modules]
        module_paths = [os.path.relpath(m, start="src").replace("\\", ".").replace(".luau", "") for m in modules]

        names_str = ' | '.join(f'"{name}"' for name in module_names)
        values_str = ' & '.join(
            f'(("{name}") -> (typeof(require(game.{path}))))'
            for name, path in zip(module_names, module_paths)
        )

        file.write(f'export type ModuleNames = {names_str}\n')
        file.write(f'export type Modules = {values_str}\n')
        file.write('\nreturn {}\n')

def main(config):
    """
    Main function to process each output path and its corresponding input paths.
    """
    for output_path, input_paths in tqdm(config.items(), desc="Processing", unit="file"):
        # Gather modules and write the Types.luau file
        modules = gather_modules(input_paths, output_path)
        
        # Ensure the output directory exists
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Write the Types.luau file (create or overwrite)
        write_types_file(output_path, modules, input_paths)

if __name__ == "__main__":
    main(config)

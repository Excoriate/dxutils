use std::process::Command;
use clap::Parser;

#[derive(Parser, Debug)]
struct Args {
    /// Install option
    #[clap(short, long)]
    install: bool,
}

#[derive(Debug)]
struct Plugin {
    name: String,
    url: String,
}

#[derive(Debug)]
struct CommandResult {
    command: String,
    error : String,
}


fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    if !args.install {
        println!("Installing...");
        let plugins = list_asdf_plugins()?;

        for plugin in plugins {
            println!("Plugin '{}'\n\tURL: {}", plugin.name, plugin.url);

            // Note the change here: we now pass a slice of strings as args
            run_command("asdf", &["plugin-add", &plugin.name])?;
            run_command("asdf", &["install", &plugin.name, "latest"])?;
            run_command("asdf", &["global", &plugin.name, "latest"])?;
        }
    } else {
        println!("Not installing...");
    }

    Ok(())
}

fn run_command(cmd: &str, args: &[&str]) -> Result<Vec<CommandResult>, Box<dyn std::error::Error>> {
    let entire_command = format!("{} {:?}", cmd, args);
    println!("Running command: {}", entire_command);

    let output = Command::new(cmd)
        .args(args)
        .status()?;

    // New Vector or array of CommandResults
    let mut command_failed: Vec<CommandResult> = Vec::new();

    if !output.success() {
        println!("Command {:?} failed with exit status '{}'", args, output);

        // Add to the vector
        let mut commands_failed_str = String::new();
        if args.is_empty() {
            commands_failed_str.push_str(cmd);
        } else {
            for arg in args {
                commands_failed_str.push_str(arg);
                commands_failed_str.push(' ');
            }
        }
    }

    // Show status of the command.
    println!("Command {:?} finished with status '{}'", args, output);

    return Ok(command_failed);
}

fn list_asdf_plugins() -> Result<Vec<Plugin>, Box<dyn std::error::Error>> {
    let output = Command::new("asdf")
        .arg("plugin-list-all")
        .output()?;

    let output = String::from_utf8(output.stdout)?;

    let plugins = output
        .lines()
        .filter_map(|line| {
            let mut parts = line.splitn(2, ' ');
            Some(Plugin {
                name: parts.next()?.to_owned(),
                url: parts.next()?.to_owned(),
            })
        })
        .collect();

    Ok(plugins)
}

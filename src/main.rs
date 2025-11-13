use clap::{Arg, ArgAction, Command};
use std::process::{Command as PCommand, Stdio};

fn main() {
    let matches = Command::new("tilt-logs")
        .about("Reads logs from Docker containers managed by Tilt.")
        .arg(Arg::new("service").required(false))
        .arg(Arg::new("follow").long("follow").short('f').action(ArgAction::SetTrue))
        .arg(Arg::new("tail").long("tail").value_name("N"))
        .arg(Arg::new("list").long("list").action(ArgAction::SetTrue))
        .arg(Arg::new("exact").long("exact").action(ArgAction::SetTrue))
        .get_matches();

    // List containers
    if matches.get_flag("list") {
        list_containers();
        return;
    }

    let service = matches.get_one::<String>("service");
    if service.is_none() {
        eprintln!("Error: <service> required unless using --list");
        std::process::exit(1);
    }
    let service = service.unwrap();

    let container = resolve_container(service, matches.get_flag("exact"));
    if container.is_none() {
        eprintln!("No container found matching: {}", service);
        list_containers();
        std::process::exit(1);
    }
    let container = container.unwrap();

    let mut cmd = PCommand::new("docker");
    cmd.arg("logs").arg(&container);

    if matches.get_flag("follow") {
        cmd.arg("--follow");
    }

    if let Some(t) = matches.get_one::<String>("tail") {
        cmd.arg("--tail").arg(t);
    }

    cmd.stdout(Stdio::inherit()).stderr(Stdio::inherit());

    let mut child = cmd.spawn().expect("Failed to run docker logs");
    let _ = child.wait();
}

fn resolve_container(pattern: &str, exact: bool) -> Option<String> {
    let list = get_container_list();
    if exact {
        return list.into_iter().find(|c| c == pattern);
    }
    let matches: Vec<String> = list.into_iter().filter(|c| c.contains(pattern)).collect();
    if matches.len() == 1 {
        Some(matches[0].clone())
    } else {
        if matches.len() > 1 {
            eprintln!("Multiple containers match '{}':", pattern);
            for m in matches {
                eprintln!("  {}", m);
            }
        }
        None
    }
}

fn get_container_list() -> Vec<String> {
    let out = PCommand::new("docker")
        .arg("ps")
        .arg("--format")
        .arg("{{.Names}}")
        .output()
        .expect("Failed to run docker ps");

    if !out.status.success() {
        eprintln!("docker ps failed");
        return vec![];
    }

    String::from_utf8_lossy(&out.stdout)
        .lines()
        .map(|s| s.to_string())
        .collect()
}

fn list_containers() {
    println!("Containers:");
    for c in get_container_list() {
        println!("  {}", c);
    }
}

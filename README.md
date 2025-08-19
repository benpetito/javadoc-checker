# JavadocChecker

JavadocChecker is a tool for scanning Java projects to check for missing Javadoc comments in source files. It generates detailed CSV reports for each project and a summary report for all scanned projects.

## Features

- Scans multiple Java projects for missing Javadoc comments
- Generates per-project CSV reports
- Produces a summary CSV with statistics
- Easy to run via a shell script

## Prerequisites

- Java (JDK 21 or higher)
- Maven
- Bash (for running the script)

## Usage


### 1. Build the JAR and Run Against Local Workspace

To build the JavadocChecker fat JAR and scan all projects under your local workspace (default: `~/workspace`):

```bash
./run_javadoc_checker.sh
```

You can specify a different workspace path:

```bash
./run_javadoc_checker.sh /path/to/your/workspace
```

**Output:**
- Individual project reports: `output-reports/<project>_javadoc_report.csv`
- Summary report: `output-reports/summary.csv`

### 2. Compare Javadoc Coverage Between Last Year and Now

To compare Javadoc coverage between a commit from last year and the latest commit for a set of repositories, use the new script:

1. Create a text file (e.g. `repo_list.txt`) with one repository URL per line:

	```
	https://github.com/example/repo1.git
	https://github.com/example/repo2.git
	...
	```

2. Run the comparison script:

	```bash
	./run_javadoc_compare.sh repo_list.txt
	```

This will:
- Clone each repository into a new directory under `./javadoc_compare_repos/`
- For each repo, check out the last commit before Jan 1, 2025, run the checker, and record results
- Check out the latest commit, run the checker, and record results
- Write a summary CSV with both previous and current coverage columns: `output-reports/summary.csv`

**Output:**
- Previous and current coverage for each repo: `output-reports/summary.csv`
- Per-repo reports for each state: `output-reports/<repo>_prev.csv` and `output-reports/<repo>_curr.csv`

## Customisation

- The shell script expects each project to have source files under `src/main/java/modules`.
- The Maven Shade plugin in the [pom.xml](pom.xml) is configured to build a fat JAR named `JavadocChecker.jar`.

## License

See [LICENSE](LICENSE) for details.

## Troubleshooting


- If you get a "Permission denied" error when trying to run a shell script, add execute permissions with:
	```bash
	chmod +x run_javadoc_checker.sh run_javadoc_compare.sh
	```
- If the script cannot find the fat JAR, ensure the Maven Shade plugin is set up correctly in `pom.xml`.
- Only projects with a `src/main/java/modules` directory are scanned.

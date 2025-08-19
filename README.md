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

### 1. Build the JAR

Run the provided shell script to build the JavadocChecker fat JAR using Maven:

```bash
./run_javadoc_checker.sh
```

This will:
- Compile the JAR using Maven
- Copy the fat JAR to the project root
- Scan all projects under your workspace directory (default: `~/workspace`)
- Generate CSV reports in the `output-reports/` directory

### 2. Specify a Custom Workspace (Optional)

You can specify a different workspace path:

```bash
./run_javadoc_checker.sh /path/to/your/workspace
```

### 3. Output

- Individual project reports: `output-reports/<project>_javadoc_report.csv`
- Summary report: `output-reports/summary.csv`

## Customisation

- The shell script expects each project to have source files under `src/main/java/modules`.
- The Maven Shade plugin in the [pom.xml](pom.xml) is configured to build a fat JAR named `JavadocChecker.jar`.

## License

See [LICENSE](LICENSE) for details.

## Troubleshooting

- If the script cannot find the fat JAR, ensure the Maven Shade plugin is set up correctly in `pom.xml`.
- Only projects with a `src/main/java/modules` directory are scanned.

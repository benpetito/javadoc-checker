import java.io.File;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.concurrent.atomic.AtomicInteger;

import com.github.javaparser.ParserConfiguration.LanguageLevel;
import com.github.javaparser.StaticJavaParser;
import com.github.javaparser.ast.CompilationUnit;
import com.github.javaparser.ast.body.ClassOrInterfaceDeclaration;
import com.github.javaparser.ast.body.MethodDeclaration;

public class JavadocChecker {
    public static void main(String[] args) throws Exception {
        // Set JavaParser language level to Java 21
		StaticJavaParser.getParserConfiguration().setLanguageLevel(LanguageLevel.JAVA_21);

		if (args.length < 3) {
			System.out.println("Usage: java JavadocChecker <source_directory> <output_csv_file> <summary_csv_append_file>");
            return;
        }

        Path root = Paths.get(args[0]);
        File csvFile = new File(args[1]);
		File summaryFile = new File(args[2]);

        AtomicInteger total = new AtomicInteger();
        AtomicInteger undocumented = new AtomicInteger();

        try (PrintWriter writer = new PrintWriter(new FileWriter(csvFile))) {
            writer.println("File,Type,Name,JavadocPresent");

            Files.walk(root)
                .filter(p -> p.toString().endsWith(".java"))
                .forEach(p -> {
                    try {
                        CompilationUnit cu = StaticJavaParser.parse(p);

                        cu.findAll(ClassOrInterfaceDeclaration.class).forEach(cls -> {
                            if (cls.isPublic()) {
                                boolean hasJavadoc = cls.getJavadoc().isPresent();
                                writer.printf("\"%s\",Class,%s,%s%n", p, cls.getName(), hasJavadoc);
                                total.incrementAndGet();
                                if (!hasJavadoc) undocumented.incrementAndGet();
                            }
                        });

                        cu.findAll(MethodDeclaration.class).forEach(method -> {
                            if (method.isPublic()) {
                                boolean hasJavadoc = method.getJavadoc().isPresent();
                                writer.printf("\"%s\",Method,%s,%s%n", p, method.getName(), hasJavadoc);
                                total.incrementAndGet();
                                if (!hasJavadoc) undocumented.incrementAndGet();
                            }
                        });

                    } catch (Exception e) {
                        System.err.println("Failed to parse: " + p + " - " + e.getMessage());
                    }
                });
        }

		double percentUndocumented = (total.get() == 0) ? 0 : 100.0 * undocumented.get() / total.get();

		// Append to summary file
		String projectName = root.getParent().getParent().getParent().getParent().getFileName().toString();
		try (PrintWriter summary = new PrintWriter(new FileWriter(summaryFile, true))) {
			summary.printf("\"%s\",%d,%d,%.2f%%%n", projectName, total.get(), undocumented.get(), percentUndocumented);
		}

        System.out.printf("Total public methods/classes: %d%n", total.get());
		System.out.printf("Without Javadoc: %d (%.2f%%)%n", undocumented.get(), percentUndocumented);
    }
}
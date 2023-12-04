package mock;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.management.ManagementFactory;
import java.lang.management.RuntimeMXBean;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;

public class App {
    public static void main( String[] args ) throws Exception {
        System.out.println(makeInformation(args));
        boolean resident = false;

        for (String arg : args) {
            if (arg.startsWith("exitCode=")) {
                // 任意の終了コードを外部から指定できるようにしている
                System.exit(Integer.parseInt(arg.replaceFirst("exitCode=", "")));
            } else if (arg.startsWith("file=")) {
                // バックグラウンド実行された場合、標準出力への出力では検証ができないので、
                // 引数で指定されたファイルにも書き出すようにする
                Path out = Path.of(arg.replaceFirst("file=", ""));
                Files.writeString(out, makeInformation(args), StandardCharsets.UTF_8);
            } else if (arg.equals("--resident-batch.enabled=true")) {
                resident = true;
            }
        }

        if (resident) {
            // 常駐バッチとして起動する
            while (true) {
                Thread.sleep(1000);
                System.out.print(".");
            }
        }
    }

    private static String makeInformation(String[] args) throws Exception {
        final RuntimeMXBean runtimeMXBean = ManagementFactory.getRuntimeMXBean();
        return "JVM引数=" + runtimeMXBean.getInputArguments() + "\n" +
                "コマンドライン引数=" + Arrays.toString(args) + "\n" +
                "process=" + obtainProcessInformation();
    }

    /**
     * このjavaプロセスの情報を ps コマンドで取得する。
     * @return このjavaプロセスの情報をpsコマンドで取得した結果
     */
    private static String obtainProcessInformation() throws IOException {
        final long pid = ProcessHandle.current().pid();
        final Process process = Runtime.getRuntime().exec(new String[]{"ps", "-fp", String.valueOf(pid)});
        try (InputStream in = process.getInputStream();
             ByteArrayOutputStream stdout = new ByteArrayOutputStream();) {
            in.transferTo(stdout);
            return stdout.toString();
        }
    }
}

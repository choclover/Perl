import java.io.FileInputStream;

/**
 * 解析class文件格式
 */
public class JavaVerParser {
  public static void main(String args[]) {
    String sourFName = "./Test01.class";
    if (args.length >= 1) {
      sourFName = args[0];
    }
    // System.out.println("sourFname is: "+ sourFName);

    try {
      // 读取文件数据,文件是当前目录下的First.class
      FileInputStream fis = new FileInputStream(sourFName);
      int length = fis.available();
      // 文件数据
      byte[] data = new byte[length];
      // 读取文件到字节数组
      fis.read(data);
      // 关闭文件
      fis.close();
      // 解析文件数据
      parseFile(data);
    } catch (Exception e) {
      System.out.println(e);
    }
  }

  private static void parseFile(byte[] data) {
    // 输出魔数
    System.out.print("/u9b54/u6570(magic number) is: 0x"); // 魔数
    System.out.print(Integer.toHexString(data[0]).substring(6).toUpperCase());
    System.out.print(Integer.toHexString(data[1]).substring(6).toUpperCase());
    System.out.print(Integer.toHexString(data[2]).substring(6).toUpperCase());
    System.out.println(Integer.toHexString(data[3]).substring(6).toUpperCase());
    // 主版本号和次版本号码
    int minor_version = ((data[4]) << 8) + data[5];
    int major_version = ((data[6]) << 8) + data[7];
    System.out.println("/u7248/u672c/u53f7(version number) is: "
        + major_version + "." + minor_version); // 版本号

    System.out.println("major.minor version 51.0 is for JDK / JRE7.0)");
    System.out.println("major.minor version 50.0 is for JDK1.6(JRE1.6)");
    System.out.println("major.minor version 49.0 is for JDK1.5(JRE1.5)");
    System.out.println("major.minor version 48.0 is for JDK1.4(JRE1.4)");
  }
}

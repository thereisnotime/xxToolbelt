//usr/bin/env jbang "$0" "$@" ; exit $?
//DEPS org.jsoup:jsoup:1.13.1
import java.util.*;
class Template {
    public static void main(String [] args) {
        System.out.println(String.join(" ",args));
    }
}
///bin/true;COMPILER_OPTIONS="-g -Wall -Wextra --std=c++14 -O1 -fsanitize=address,undefined";THIS_FILE="$(cd "$(dirname "$0")"; pwd -P)/$(basename "$0")";OUT_FILE="/tmp/build-cache/$THIS_FILE";mkdir -p "$(dirname "$OUT_FILE")";test "$THIS_FILE" -ot "$OUT_FILE" || $(which clang++ || which g++) -xc++ $COMPILER_OPTIONS "$THIS_FILE" -o "$OUT_FILE" || exit;exec "$OUT_FILE" "$@"
#include <iostream>

int main() {
  std::cerr << "Hello, world!" << std::endl;
  return 0;
}
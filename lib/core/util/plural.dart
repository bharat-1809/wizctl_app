/// "1 light", "3 lights". The app never localises, so this is enough.
String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

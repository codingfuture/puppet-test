node default {
  notify{"'${lookup(classes,Any,unique)}'":}
}
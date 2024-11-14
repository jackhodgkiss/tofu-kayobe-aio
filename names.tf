locals {
  scientists = [
    "einstein", "curie", "newton", "bohr", "galilei",
    "feynman", "hawking", "heisenberg", "planck",
    "schrodinger", "mendeleev", "pauling", "franklin",
    "lavoisier", "lewis", "hooke", "darwin",
    "mendel", "goodall", "mcclintock"
  ]
}

resource "random_shuffle" "scientist" {
  input        = local.scientists
  result_count = 1
}

resource "random_id" "random_uuid" {
  byte_length = 4
}
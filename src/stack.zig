const sexp = @import("sexp.zig");
const Sexp = sexp.Sexp;

pub const SexpStack = struct {
    .head = 0,
    .arr = [100]Sexp,
};

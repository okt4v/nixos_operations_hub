vim.opt_local.commentstring = "; %s"
vim.opt_local.expandtab = false
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4

local ok, ls = pcall(require, "luasnip")
if not ok then return end

local s   = ls.snippet
local t   = ls.text_node
local i   = ls.insert_node
local c   = ls.choice_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

ls.add_snippets("nasm", {

  -- Sections
  s("section", c(1, {
    t("section .text"),
    t("section .data"),
    t("section .bss"),
    t("section .rodata"),
  })),
  s("stext",  t("section .text")),
  s("sdata",  t("section .data")),
  s("sbss",   t("section .bss")),

  -- Entry point skeleton
  s("start", fmt([[
section .data
{}

section .bss
{}

section .text
global _start

_start:
{}
]], { i(1, "; data"), i(2, "; bss"), i(3, "; code") })),

  -- Global / extern
  s("global", fmt("global {}", { i(1, "_start") })),
  s("extern", fmt("extern {}", { i(1, "name") })),

  -- Data declarations
  s("db",  fmt("{} db {}", { i(1, "name"), i(2, "0") })),
  s("dw",  fmt("{} dw {}", { i(1, "name"), i(2, "0") })),
  s("dd",  fmt("{} dd {}", { i(1, "name"), i(2, "0") })),
  s("dq",  fmt("{} dq {}", { i(1, "name"), i(2, "0") })),
  s("resb", fmt("{} resb {}", { i(1, "name"), i(2, "1") })),
  s("resw", fmt("{} resw {}", { i(1, "name"), i(2, "1") })),
  s("resd", fmt("{} resd {}", { i(1, "name"), i(2, "1") })),
  s("resq", fmt("{} resq {}", { i(1, "name"), i(2, "1") })),
  s("str",  fmt('{} db "{}", 0\n{}_len equ $ - {}', { i(1, "name"), i(2, "hello"), rep(1), rep(1) })),
  s("equ",  fmt("{} equ {}", { i(1, "NAME"), i(2, "value") })),

  -- Preprocessor
  s("define", fmt("%define {} {}", { i(1, "NAME"), i(2, "value") })),
  s("macro",  fmt("%macro {} {}\n\t{}\n%endmacro", { i(1, "name"), i(2, "0"), i(3) })),
  s("ifdef",  fmt("%ifdef {}\n\t{}\n%endif", { i(1, "SYMBOL"), i(2) })),

  -- Linux x86-64 syscalls
  s("exit", fmt([[
mov rax, 60
mov rdi, {}
syscall]], { i(1, "0") })),

  s("write", fmt([[
mov rax, 1
mov rdi, {}
mov rsi, {}
mov rdx, {}
syscall]], { i(1, "1"), i(2, "msg"), i(3, "msg_len") })),

  s("read", fmt([[
mov rax, 0
mov rdi, {}
mov rsi, {}
mov rdx, {}
syscall]], { i(1, "0"), i(2, "buf"), i(3, "buf_len") })),

  -- Subroutine
  s("proc", fmt([[
{}:
\tpush rbp
\tmov rbp, rsp
\t{}
\tpop rbp
\tret]], { i(1, "name"), i(2) })),

}, { key = "nasm" })

-- Kernel / bare-metal snippets
ls.add_snippets("nasm", {

  -- [BITS] and [ORG]
  s("bits16", t("[BITS 16]")),
  s("bits32", t("[BITS 32]")),
  s("bits64", t("[BITS 64]")),
  s("org",    fmt("[ORG {}]", { i(1, "0x7C00") })),

  -- MBR bootloader skeleton
  s("mbr", fmt(
    "[BITS 16]\n[ORG 0x7C00]\n\n_start:\n\t{}\n\ntimes 510 - ($ - $$) db 0\ndw 0xAA55",
    { i(1) }
  )),

  -- Multiboot2 header (for GRUB)
  s("mb2", t({
    "section .multiboot",
    "align 8",
    "mb2_start:",
    "\tdd 0xE85250D6",
    "\tdd 0                                          ; arch: i386 protected mode",
    "\tdd mb2_end - mb2_start",
    "\tdd -(0xE85250D6 + 0 + (mb2_end - mb2_start)) ; checksum",
    "\t; end tag",
    "\tdw 0",
    "\tdw 0",
    "\tdd 8",
    "mb2_end:",
  })),

  -- Flat 32-bit GDT (null, code, data)
  s("gdt", t({
    "gdt_start:",
    "\tdq 0",
    "gdt_code:",
    "\tdw 0xFFFF",
    "\tdw 0x0000",
    "\tdb 0x00",
    "\tdb 0x9A       ; P=1 DPL=0 exec/read",
    "\tdb 0xCF       ; G=1 D/B=1",
    "\tdb 0x00",
    "gdt_data:",
    "\tdw 0xFFFF",
    "\tdw 0x0000",
    "\tdb 0x00",
    "\tdb 0x92       ; P=1 DPL=0 read/write",
    "\tdb 0xCF",
    "\tdb 0x00",
    "gdt_end:",
    "gdt_descriptor:",
    "\tdw gdt_end - gdt_start - 1",
    "\tdd gdt_start",
  })),

  -- Switch real mode -> protected mode
  s("pm_switch", t({
    "cli",
    "lgdt [gdt_descriptor]",
    "mov eax, cr0",
    "or eax, 1",
    "mov cr0, eax",
    "jmp 0x08:pm_entry",
    "",
    "[BITS 32]",
    "pm_entry:",
    "\tmov ax, 0x10",
    "\tmov ds, ax",
    "\tmov es, ax",
    "\tmov fs, ax",
    "\tmov gs, ax",
    "\tmov ss, ax",
  })),

  -- Switch protected mode -> long mode
  s("lm_switch", t({
    "; enable PAE (CR4 bit 5)",
    "mov eax, cr4",
    "or eax, (1 << 5)",
    "mov cr4, eax",
    "",
    "; point CR3 at PML4",
    "mov eax, pml4",
    "mov cr3, eax",
    "",
    "; set LME in EFER MSR",
    "mov ecx, 0xC0000080",
    "rdmsr",
    "or eax, (1 << 8)",
    "wrmsr",
    "",
    "; enable paging + PE",
    "mov eax, cr0",
    "or eax, 0x80000001",
    "mov cr0, eax",
    "jmp 0x08:lm_entry",
    "",
    "[BITS 64]",
    "lm_entry:",
  })),

  -- Interrupt service routine stub
  s("isr", fmt(
    "{}:\n\tpush rbp\n\tmov rbp, rsp\n\t{}\n\tpop rbp\n\tiretq",
    { i(1, "isr_name"), i(2) }
  )),

  -- PIC remap (master 0x20-0x27, slave 0x28-0x2F)
  s("pic_remap", t({
    "mov al, 0x11",
    "out 0x20, al        ; ICW1: init master",
    "out 0xA0, al        ; ICW1: init slave",
    "mov al, 0x20",
    "out 0x21, al        ; ICW2: master IRQ0 -> INT 0x20",
    "mov al, 0x28",
    "out 0xA1, al        ; ICW2: slave IRQ8 -> INT 0x28",
    "mov al, 0x04",
    "out 0x21, al        ; ICW3: slave on IRQ2",
    "mov al, 0x02",
    "out 0xA1, al        ; ICW3: slave cascade id",
    "mov al, 0x01",
    "out 0x21, al        ; ICW4: 8086 mode",
    "out 0xA1, al",
    "mov al, 0xFF",
    "out 0x21, al        ; mask all IRQs",
    "out 0xA1, al",
  })),

  -- Port I/O
  s("outb", fmt("mov dx, {}\nmov al, {}\nout dx, al", { i(1, "port"), i(2, "0") })),
  s("inb",  fmt("mov dx, {}\nin al, dx",               { i(1, "port") })),
  s("outw", fmt("mov dx, {}\nmov ax, {}\nout dx, ax",  { i(1, "port"), i(2, "0") })),
  s("inw",  fmt("mov dx, {}\nin ax, dx",               { i(1, "port") })),
  s("outd", fmt("mov dx, {}\nmov eax, {}\nout dx, eax",{ i(1, "port"), i(2, "0") })),
  s("ind",  fmt("mov dx, {}\nin eax, dx",              { i(1, "port") })),
  s("io_wait", t("out 0x80, al    ; ~1us I/O delay")),

  -- VGA text mode character write (0xB8000, attr 0x07 = light grey on black)
  s("vga", fmt(
    "mov byte [0xB8000 + {}], {}\nmov byte [0xB8000 + {} + 1], 0x07",
    { i(1, "0"), i(2, "'A'"), rep(1) }
  )),

  -- Descriptor table loads
  s("lgdt",  fmt("lgdt [{}]", { i(1, "gdt_descriptor") })),
  s("lidt",  fmt("lidt [{}]", { i(1, "idt_descriptor") })),

  -- CPUID
  s("cpuid", fmt("mov eax, {}\ncpuid", { i(1, "0x0") })),

  -- Infinite halt (kernel panic / end of execution)
  s("hang", t({ ".hang:", "\tcli", "\thlt", "\tjmp .hang" })),

}, { key = "nasm_kernel" })

-- IDT, page tables, stack
ls.add_snippets("nasm", {

  -- 64-bit interrupt gate macro (use at assembly time to build static IDT)
  s("idt_gate", t({
    "%macro idt_gate 1",
    "\tdw %1 & 0xFFFF",
    "\tdw 0x08                   ; kernel code segment",
    "\tdb 0                      ; IST = 0",
    "\tdb 0x8E                   ; P=1 DPL=0 64-bit interrupt gate",
    "\tdw (%1 >> 16) & 0xFFFF",
    "\tdd (%1 >> 32) & 0xFFFFFFFF",
    "\tdd 0",
    "%endmacro",
  })),

  -- IDT: 256 empty entries in BSS (populate at runtime) + descriptor
  s("idt", t({
    "section .bss",
    "align 16",
    "idt_start:",
    "\tresb 16 * 256",
    "idt_end:",
    "",
    "section .data",
    "idt_descriptor:",
    "\tdw idt_end - idt_start - 1",
    "\tdq idt_start",
  })),

  -- Page table BSS allocations (PML4 -> PDPT -> PD, for 2MB huge pages)
  s("pgtbl", t({
    "section .bss",
    "align 4096",
    "pml4: resb 4096",
    "pdpt: resb 4096",
    "pd:   resb 4096",
  })),

  -- Identity-map first 1GB using 2MB huge pages (run in 32-bit protected mode)
  s("pgtbl_init", t({
    "; PML4[0] -> PDPT",
    "mov eax, pdpt",
    "or  eax, 0x03",
    "mov dword [pml4], eax",
    "",
    "; PDPT[0] -> PD",
    "mov eax, pd",
    "or  eax, 0x03",
    "mov dword [pdpt], eax",
    "",
    "; PD[0..511]: 2MB huge pages (identity-map 1GB)",
    "; mul puts result in edx:eax; edx=0 since max = 0x3FE00000 < 4GB",
    "xor ecx, ecx",
    ".map_pd:",
    "\tmov eax, 0x200000",
    "\tmul ecx",
    "\tor  eax, 0x83           ; present + writable + huge (PS bit)",
    "\tmov [pd + ecx*8], eax   ; high dword = 0 (BSS-zeroed)",
    "\tinc ecx",
    "\tcmp ecx, 512",
    "\tjl  .map_pd",
  })),

  -- Stack: BSS declaration with configurable size
  s("stack", fmt(
    "section .bss\nalign 16\nstack_bottom:\n\tresb {}\nstack_top:",
    { i(1, "16384") }
  )),

  -- Stack init (set rsp to top of stack, clear frame pointer)
  s("stack_init", fmt(
    "mov rsp, {}\nxor rbp, rbp",
    { i(1, "stack_top") }
  )),

}, { key = "nasm_pgtbl_idt" })

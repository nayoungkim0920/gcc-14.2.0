#!/usr/bin/gawk
#
# A simple script that generates loongarch-evolution.h
# from genopts/isa-evolution.in
#
# Copyright (C) 2021-2024 Free Software Foundation, Inc.
#
# This file is part of GCC.
#
# GCC is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# GCC is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
# License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GCC; see the file COPYING3.  If not see
# <http://www.gnu.org/licenses/>.

BEGIN {
    # isa_version_major[]
    # isa_version_minor[]
    # cpucfg_word[]
    # cpucfg_bit_in_word[]
    # name_capitalized[]
    # comment[]
}

{
    cpucfg_word[NR] = $1
    cpucfg_bit_in_word[NR] = $2
    name[NR] = gensub(/-/, "_", "g", $3)
    name_capitalized[NR] = toupper(name[NR])
    isa_version_major[NR] = gensub(/^([1-9][0-9]*)\.([0-9]+)$/, "\\1", 1, $4)
    isa_version_minor[NR] = gensub(/^([1-9][0-9]*)\.([0-9]+)$/, "\\2", 1, $4)

    $1 = $2 = $3 = $4 = ""
    sub (/^\s*/, "")
    comment[NR] = $0
}

function copyright_header(from_year,to_year)
{
    print "   Copyright (C) " from_year "-" to_year \
          " Free Software Foundation, Inc."
    print ""
    print "This file is part of GCC."
    print ""
    print "GCC is free software; you can redistribute it and/or modify"
    print "it under the terms of the GNU General Public License as published by"
    print "the Free Software Foundation; either version 3, or (at your option)"
    print "any later version."
    print ""
    print "GCC is distributed in the hope that it will be useful,"
    print "but WITHOUT ANY WARRANTY; without even the implied warranty of"
    print "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
    print "GNU General Public License for more details."
    print ""
    print "You should have received a copy of the GNU General Public License"
    print "along with GCC; see the file COPYING3.  If not see"
    print "<http://www.gnu.org/licenses/>."
}

function gen_cpucfg_map()
{
    print "static constexpr struct {"
    print "  int cpucfg_word;"
    print "  unsigned int cpucfg_bit;"
    print "  HOST_WIDE_INT isa_evolution_bit;"
    print "} cpucfg_map[] = {"

    for (i = 1; i <= NR; i++)
    printf ("  { %d, 1u << %d, OPTION_MASK_ISA_%s },\n",
            cpucfg_word[i], cpucfg_bit_in_word[i], name_capitalized[i])

    print "};"
}

function gen_cpucfg_useful_idx()
{
    split("0 1 2 16 17 18 19", init_useful_idx)

    delete idx_bucket

    for (i in init_useful_idx)
        idx_bucket[init_useful_idx[i]] = 1
    delete init_useful_idx

    for (i in cpucfg_word)
        idx_bucket[cpucfg_word[i]] = 1

    delete idx_list
    for (i in idx_bucket)
        idx_list[length(idx_list)-1] = i+0
    delete idx_bucket

    asort (idx_list)

    print "static constexpr int cpucfg_useful_idx[] = {"
    for (i in idx_list)
        printf("  %d,\n", idx_list[i])
    print "};"

    print ""

    printf ("static constexpr int N_CPUCFG_WORDS = %d;\n",
            idx_list[length(idx_list)] + 1)

    delete idx_list
}

function gen_evolution_decl()
{
    print "/* ISA evolution features */"
    print "enum {"

    for (i = 1; i <= NR; i++)
    print "  EVO_" name_capitalized[i] " = " i - 1 ","

    print "  N_EVO_FEATURES = " NR
    print "};"
    print ""

    print "/* Condition macros */"
    for (i = 1; i <= NR; i++)
    printf ("#define ISA_HAS_%s \\\n" \
            "  (la_target.isa.evolution & OPTION_MASK_ISA_%s)\n",
            name_capitalized[i], name_capitalized[i])
    print ""

    print "/* Bitmasks on la_target.isa.evolution.  */"
    print "extern int la_evo_feature_masks[N_EVO_FEATURES];"
    print ""
    print "/* Builtin macro names for the evolution features.  */"
    print "extern const char* la_evo_macro_name[N_EVO_FEATURES];"
    print ""
    print "/* The ISA version where a specific feature is introduced.  */"
    print "extern int la_evo_version_major[N_EVO_FEATURES];"
    print "extern int la_evo_version_minor[N_EVO_FEATURES];"
}

function gen_full_header()
{
    print "/* Generated automatically by \"genstr\" from \"isa-evolution.in\"."
    print "   Please do not edit this file directly."
    print ""

    copyright_header(2023, 2024)

    print "*/"
    print ""

    print "#ifndef LOONGARCH_EVOLUTION_H"
    print "#define LOONGARCH_EVOLUTION_H"
    print ""
    print "#if !defined(IN_LIBGCC2) && !defined(IN_TARGET_LIBS) && !defined(IN_RTS)"
    print ""
    print "#include \"options.h\""
    print ""

    gen_cpucfg_map()

    print ""

    gen_cpucfg_useful_idx()

    print ""

    gen_evolution_decl()

    print ""
    print "#endif"
    print ""
    print "#endif /* LOONGARCH_EVOLUTION_H */"
}


function gen_full_source()
{
    print "/* Generated automatically by \"genstr\" from \"isa-evolution.in\"."
    print "   Please do not edit this file directly."
    print ""

    copyright_header(2023, 2024)

    print "*/"
    print ""
    print "#include \"config.h\""
    print "#include \"system.h\""
    print "#include \"coretypes.h\""
    print "#include \"options.h\""
    print ""
    print "#include \"loongarch-evolution.h\""
    print ""

    print "int la_evo_feature_masks[] = {";
    for (i = 1; i <= NR; i++)
    print "  OPTION_MASK_ISA_" name_capitalized[i] ","
    print "};"
    print ""

    print "const char* la_evo_macro_name[] = {";
    for (i = 1; i <= NR; i++)
    print "  \"__loongarch_" name[i] "\","
    print "};"
    print ""


    print "int la_evo_version_major[] = {"
    for (i = 1; i <= NR; i++)
    print "  " isa_version_major[i] ",    /* " name_capitalized[i] " */"
    print "};"
    print ""

    print "int la_evo_version_minor[] = {"
    for (i = 1; i <= NR; i++)
    print "  " isa_version_minor[i] ",    /* " name_capitalized[i] " */"
    print "};"
}

END {
    if (header_p)
        gen_full_header()
    else
        gen_full_source()
}
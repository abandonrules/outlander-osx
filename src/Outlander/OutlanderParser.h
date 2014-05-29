#import <PEGKit/PKParser.h>

enum {
    OUTLANDERPARSER_TOKEN_KIND_SCRIPT = 14,
    OUTLANDERPARSER_TOKEN_KIND_ALIAS,
    OUTLANDERPARSER_TOKEN_KIND_PUT,
    OUTLANDERPARSER_TOKEN_KIND_POUND,
    OUTLANDERPARSER_TOKEN_KIND_GOTO,
    OUTLANDERPARSER_TOKEN_KIND_EQUALS,
    OUTLANDERPARSER_TOKEN_KIND_VAR,
    OUTLANDERPARSER_TOKEN_KIND_HIGHLIGHT,
    OUTLANDERPARSER_TOKEN_KIND_SETVARIABLE,
    OUTLANDERPARSER_TOKEN_KIND_PAUSE,
    OUTLANDERPARSER_TOKEN_KIND_COLON,
};

@interface OutlanderParser : PKParser

@end

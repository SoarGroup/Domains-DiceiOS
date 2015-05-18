#ifndef LIARSDICELOG_H
#define LIARSDICELOG_H

#import "DDLog.h"

// We want to use the following log levels:
//
// Fatal
// Error
// Info
// GameHistory
// Debug
//
// All we have to do is undefine the default values,
// and then simply define our own however we want.

// First undefine the default stuff we don't want to use.

#undef LOG_FLAG_ERROR
#undef LOG_FLAG_WARN
#undef LOG_FLAG_INFO
#undef LOG_FLAG_DEBUG
#undef LOG_FLAG_VERBOSE

#undef LOG_LEVEL_ERROR
#undef LOG_LEVEL_WARN
#undef LOG_LEVEL_INFO
#undef LOG_LEVEL_DEBUG
#undef LOG_LEVEL_VERBOSE

#undef LOG_ERROR
#undef LOG_WARN
#undef LOG_INFO
#undef LOG_DEBUG
#undef LOG_VERBOSE

#undef DDLogError
#undef DDLogWarn
#undef DDLogInfo
#undef DDLogDebug
#undef DDLogVerbose

#undef DDLogCError
#undef DDLogCWarn
#undef DDLogCInfo
#undef DDLogCDebug
#undef DDLogCVerbose

// Now define everything how we want it

#define LOG_FLAG_FATAL          (1 << 0)  // 0...000001
#define LOG_FLAG_ERROR          (1 << 1)  // 0...000010
#define LOG_FLAG_INFO           (1 << 2)  // 0...000100
#define LOG_FLAG_GAMEHISTORY    (1 << 3)  // 0...001000
#define LOG_FLAG_GAMEKIT        (1 << 4)  // 0...010000
#define LOG_FLAG_DEBUG          (1 << 5)  // 0...100000
#define LOG_FLAG_SOAR           (1 << 6)  // 0..1000000

#define LOG_LEVEL_FATAL         (LOG_FLAG_FATAL)                                  // 0...000001
#define LOG_LEVEL_ERROR         (LOG_FLAG_ERROR         | LOG_LEVEL_FATAL       ) // 0...000011
#define LOG_LEVEL_INFO          (LOG_FLAG_INFO          | LOG_LEVEL_ERROR       ) // 0...000111
#define LOG_LEVEL_GAMEHISTORY   (LOG_FLAG_GAMEHISTORY   | LOG_LEVEL_INFO        ) // 0...001111
#define LOG_LEVEL_GAMEKIT       (LOG_FLAG_GAMEKIT       | LOG_LEVEL_GAMEHISTORY ) // 0...001111
#define LOG_LEVEL_DEBUG         (LOG_FLAG_DEBUG         | LOG_FLAG_GAMEKIT      ) // 0...011111
#define LOG_LEVEL_SOAR          (LOG_FLAG_SOAR          | LOG_FLAG_DEBUG        ) // 0...111111

#define LOG_FATAL           (ddLogLevel & LOG_FLAG_FATAL        )
#define LOG_ERROR           (ddLogLevel & LOG_FLAG_ERROR        )
#define LOG_INFO            (ddLogLevel & LOG_FLAG_INFO         )
#define LOG_GAMEHISTORY     (ddLogLevel & LOG_FLAG_GAMEHISTORY  )
#define LOG_GAMEKIT         (ddLogLevel & LOG_FLAG_GAMEKIT      )
#define LOG_DEBUG           (ddLogLevel & LOG_FLAG_DEBUG        )
#define LOG_SOAR            (ddLogLevel & LOG_FLAG_SOAR         )

#define DDLogFatal(frmt, ...)            SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_FATAL,        0, frmt, ##__VA_ARGS__)
#define DDLogError(frmt, ...)            SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_ERROR,        0, frmt, ##__VA_ARGS__)
#define DDLogInfo(frmt, ...)            ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_INFO,         0, frmt, ##__VA_ARGS__)
#define DDLogGameHistory(frmt, ...)     ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_GAMEHISTORY,  0, frmt, ##__VA_ARGS__)
#define DDLogGameKit(frmt, ...)         ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_GAMEKIT,      0, frmt, ##__VA_ARGS__)
#define DDLogDebug(frmt, ...)           ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_DEBUG,        0, frmt, ##__VA_ARGS__)
#define DDLogSoar(frmt, ...)            ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_SOAR,         0, frmt, ##__VA_ARGS__)

#define DDLogCFatal(frmt, ...)            SYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_FATAL,       0, frmt, ##__VA_ARGS__)
#define DDLogCError(frmt, ...)            SYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_ERROR,       0, frmt, ##__VA_ARGS__)
#define DDLogCInfo(frmt, ...)            ASYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_INFO,        0, frmt, ##__VA_ARGS__)
#define DDLogCGameHistory(frmt, ...)     ASYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_GAMEHISTORY, 0, frmt, ##__VA_ARGS__)
#define DDLogCGameKit(frmt, ...)         ASYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_GAMEKIT,     0, frmt, ##__VA_ARGS__)
#define DDLogCDebug(frmt, ...)           ASYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_DEBUG,       0, frmt, ##__VA_ARGS__)
#define DDLogCSoar(frmt, ...)            ASYNC_LOG_C_MAYBE(ddLogLevel, LOG_FLAG_SOAR,        0, frmt, ##__VA_ARGS__)

#endif

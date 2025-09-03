//
//  EZHistoryDB.m
//  Easydict
//
//  Created by Assistant on 2025/09/03.
//

#import "EZHistoryDB.h"
#import "EZQueryResult.h"
#import "EZQueryService.h"
#import "EZLog.h"

// Use FMDB if available; otherwise provide a no-op fallback so code compiles
#if __has_include(<FMDB/FMDB.h>)
#import <FMDB/FMDB.h>
#define EZ_HAS_FMDB 1
#else
#define EZ_HAS_FMDB 0
#endif

static NSString *const kHistoryDBFileName = @"history.sqlite";

@interface EZHistoryDB ()

#if EZ_HAS_FMDB
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
#endif

@end

@implementation EZHistoryDB

static EZHistoryDB *_instance;

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        [_instance setupIfNeeded];
    });
    return _instance;
}

- (NSString *)databasePath {
    NSArray<NSURL *> *urls = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *dir = urls.firstObject;
    NSURL *appDir = [dir URLByAppendingPathComponent:@"Easydict" isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:appDir withIntermediateDirectories:YES attributes:nil error:nil];
    return [[appDir URLByAppendingPathComponent:kHistoryDBFileName] path];
}

- (void)setupIfNeeded {
#if EZ_HAS_FMDB
    if (self.dbQueue) { return; }

    NSString *path = [self databasePath];
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = @"CREATE TABLE IF NOT EXISTS translation_history (\n"
                          "id INTEGER PRIMARY KEY AUTOINCREMENT,\n"
                          "created_at REAL NOT NULL,\n"
                          "service_id TEXT,\n"
                          "from_lang TEXT,\n"
                          "to_lang TEXT,\n"
                          "query_text TEXT NOT NULL,\n"
                          "translated_text TEXT,\n"
                          "raw_json TEXT\n"
                          ")";
        BOOL ok = [db executeUpdate:sql];
        if (!ok) {
            MMLogError(@"create table failed: %@", db.lastError);
        }
    }];
#endif
}

- (void)saveResult:(EZQueryResult *)result service:(EZQueryService *)service {
#if EZ_HAS_FMDB
    if (!result) { return; }
    [self setupIfNeeded];

    NSString *serviceId = service.serviceTypeWithUniqueIdentifier ?: @"";
    NSString *from = result.from ?: @"";
    NSString *to = result.to ?: @"";
    NSString *query = result.queryText ?: @"";
    NSString *translated = result.translatedText ?: @"";

    // Serialize raw if available, fallback to a safe string when not JSON-serializable
    NSString *rawJSON = nil;
    id raw = result.raw;
    if (raw) {
        if ([NSJSONSerialization isValidJSONObject:raw]) {
            NSError *err = nil;
            NSData *data = [NSJSONSerialization dataWithJSONObject:raw options:0 error:&err];
            if (data && !err) {
                rawJSON = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
        } else if ([raw isKindOfClass:[NSData class]]) {
            NSData *rawData = (NSData *)raw;
            rawJSON = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
            if (!rawJSON) {
                rawJSON = [rawData base64EncodedStringWithOptions:0];
            }
        } else if ([raw isKindOfClass:[NSString class]]) {
            rawJSON = (NSString *)raw;
        } else {
            rawJSON = [raw description];
        }
    }

    NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];

    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL ok = [db executeUpdate:@"INSERT INTO translation_history (created_at, service_id, from_lang, to_lang, query_text, translated_text, raw_json) VALUES (?, ?, ?, ?, ?, ?, ?)", @(ts), serviceId, from, to, query, translated, rawJSON ?: [NSNull null]];
        if (!ok) {
            MMLogError(@"insert history failed: %@", db.lastError);
        }
    }];
#else
    // If FMDB is not available, just log once to hint installation.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MMLogWarn(@"FMDB not found. Install FMDB (CocoaPods/SPM) to enable database caching.");
    });
#endif
}

- (NSArray<NSDictionary *> *)recentRecordsWithLimit:(NSInteger)limit offset:(NSInteger)offset {
#if EZ_HAS_FMDB
    __block NSMutableArray *rows = [NSMutableArray array];
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = @"SELECT created_at, service_id, from_lang, to_lang, query_text, translated_text, raw_json FROM translation_history ORDER BY created_at DESC LIMIT ? OFFSET ?";
        FMResultSet *rs = [db executeQuery:sql, @(limit), @(offset)];
        while ([rs next]) {
            NSMutableDictionary *row = [NSMutableDictionary dictionary];
            row[@"created_at"] = @([rs doubleForColumn:@"created_at"]);
            row[@"service_id"] = [rs stringForColumn:@"service_id"] ?: @"";
            row[@"from_lang"] = [rs stringForColumn:@"from_lang"] ?: @"";
            row[@"to_lang"] = [rs stringForColumn:@"to_lang"] ?: @"";
            row[@"query_text"] = [rs stringForColumn:@"query_text"] ?: @"";
            row[@"translated_text"] = [rs stringForColumn:@"translated_text"] ?: @"";
            row[@"raw_json"] = [rs stringForColumn:@"raw_json"] ?: @"";
            [rows addObject:row];
        }
        [rs close];
    }];
    return rows;
#else
    return @[];
#endif
}

- (void)clearAll {
#if EZ_HAS_FMDB
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL ok = [db executeUpdate:@"DELETE FROM translation_history"];
        if (!ok) {
            MMLogError(@"clear history failed: %@", db.lastError);
        }
    }];
#endif
}

@end



//
//  EZHistoryDB.h
//  Easydict
//
//  Created by Assistant on 2025/09/03.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class EZQueryResult, EZQueryService;

@interface EZHistoryDB : NSObject

+ (instancetype)shared;

/// Ensure database and tables are created.
- (void)setupIfNeeded;

/// Save full translation content for one service result.
- (void)saveResult:(EZQueryResult *)result service:(EZQueryService *)service;

/// Fetch recent history. Each record is NSDictionary with keys:
/// created_at(double), service_id, from_lang, to_lang, query_text, translated_text, raw_json
- (NSArray<NSDictionary *> *)recentRecordsWithLimit:(NSInteger)limit offset:(NSInteger)offset;

/// Remove all history records.
- (void)clearAll;

@end

NS_ASSUME_NONNULL_END



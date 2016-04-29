#import <CloudMine/CMCoding.h>
#import <ResearchKit/ResearchKit.h>

typedef void(^CMHSaveCompletion)(NSString *_Nullable uploadStatus, NSError *_Nullable error);
typedef void(^CMHFetchCompletion)(NSArray *_Nullable results, NSError *_Nullable error);

/**
 * This category conforms the `ORKResult` class and subclasses to the `CMCoding`
 * protocol. This allows them to be serialized and stored in CloudMine's
 * HIPAA compliant Connected Health Cloud.
 */
@interface ORKResult (CMHealth)<CMCoding>
@end

/**
 *  This category adds methods to the ResearchKit framework's `ORKTaskResult` class 
 *  and subclasses. The methods make storing and fetching ResearchKit data to and
 *  from CloudMine's HIPAA compliant Connected Health Cloud completely seamless.
 */
@interface ORKTaskResult (CMHealth)<CMCoding>

/**
 *  Convenience method for saving a given result with an empty study descriptor.
 *
 *  @see -cmh_saveToStudyWithDescriptor:withCompletion:
 */
- (void)cmh_saveWithCompletion:(_Nullable CMHSaveCompletion)block;

/**
 *  Serialize the current `ORKTaskResult` instance (or subclass), belonging to the
 *  study with descriptor, and push it to CloudMine.
 *
 *  @param descriptor The descriptor of the study to which this result belongs.
 *  @param block Executes when the request completes successfully or fails with an error.
 */
- (void)cmh_saveToStudyWithDescriptor:(NSString *_Nullable)descriptor
                       withCompletion:(_Nullable CMHSaveCompletion)block;

/**
 *  Convenience method for fetching results with an empty study descriptor.
 *
 *  @see +cmh_fetchUserResultsForStudyWithDescriptor:withCompletion:
 */
+ (void)cmh_fetchUserResultsWithCompletion:(_Nullable CMHFetchCompletion)block;

/**
 *  Fetch all results of the calling class for the study with a given descriptor.
 *  Callback returns an empty array if no results of the calling class, with the given
 *  descriptor, are present.
 *
 *  @warning Calling this method includes an implicit filter for the class of the caller,
 *  i.e. `[ORKTaskResult cmh_cmh_fetchUserResultsForStudyWithDescriptor:withCompletion]` will
 *  return only top level `ORKTaskResult` objects.
 *
 *  @param descriptor The descriptor of the study for which results are desired.
 *  @param block Executes when the request succeeds or fails with an error.
 */
+ (void)cmh_fetchUserResultsForStudyWithDescriptor:(NSString *_Nullable)descriptor
                                    withCompletion:(_Nullable CMHFetchCompletion)block;

/**
 *  Convenience method for fetching results by ResearchKit identifier with an empty
 *  study descriptor.
 *
 *  @see + cmh_fetchUserResultsForStudyWithDescriptor:andIdentifier:withCompletion:
 */
+ (void)cmh_fetchUserResultsForStudyWithIdentifier:(NSString *_Nullable)identifier
                                    withCompletion:(_Nullable CMHFetchCompletion)block;

/**
 *  Fetch all results of the calling class, for the study with a given descriptor,
 *  where the top level object has the given identifier.
 *
 *  @warning Calling this method includes an implicit filter for the class of the caller.
 *
 *  @param descriptor The descriptor of the study for which results are desired.
 *  @param identifier The ResearchKit identifier property of the top level result desired.
 *  @param block Executes when the request succeeds or fails with an error.
 */
+ (void)cmh_fetchUserResultsForStudyWithDescriptor:(NSString *_Nullable)descriptor
                                     andIdentifier:(NSString *_Nullable)identifier
                                    withCompletion:(_Nullable CMHFetchCompletion)block;

/**
 *  Convenience method for querying results with an empty study descriptor.
 *
 *  @see +cmh_fetchUserResultsForStudyWithQuery:withCompletion:
 */
+ (void)cmh_fetchUserResultsForStudyWithQuery:(NSString *_Nullable)query
                               withCompletion:(_Nullable CMHFetchCompletion)block;

/**
 *  Fetch all results of the calling class for the study with a given descriptor
 *  that also match the provided query. Queries are currently CloudMine query
 *  syntax.
 *
 *  @warning The query syntax will likely change before a 1.0 release of this
 *  SDK, in favor of Lucene Elasticsearch.
 *
 *  @param descriptor The descriptor of the study for which results are desired.
 *  @param query The query to apply to the `ORKTaskResult` object (or subclass).
 *  @param block Executes when the request succeeds of rails with an error.
 */
+ (void)cmh_fetchUserResultsForStudyWithDescriptor:(NSString *_Nullable)descriptor
                                          andQuery:(NSString *_Nullable)query
                                    withCompletion:(_Nullable CMHFetchCompletion)block;
@end

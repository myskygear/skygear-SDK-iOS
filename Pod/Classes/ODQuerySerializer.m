//
//  ODPredicateSerializer.m
//  Pods
//
//  Created by Patrick Cheung on 14/3/15.
//
//

#import "ODQuerySerializer.h"
#import "ODRecordSerialization.h"
#import "ODReference.h"
#import "ODDataSerialization.h"

@implementation ODQuerySerializer

+ (instancetype)serializer
{
    return [[ODQuerySerializer alloc] init];
}

- (NSString *)nameWithPredicateOperatorType:(NSPredicateOperatorType)operatorType
{
    switch (operatorType) {
        case NSEqualToPredicateOperatorType:
            return @"eq";
        case NSGreaterThanPredicateOperatorType:
            return @"gt";
        case NSGreaterThanOrEqualToPredicateOperatorType:
            return @"gte";
        case NSLessThanPredicateOperatorType:
            return @"lt";
        case NSLessThanOrEqualToPredicateOperatorType:
            return @"lte";
        case NSNotEqualToPredicateOperatorType:
            return @"neq";
        default:
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Given NSPredicateOperatorType `%u` is not supported.", (unsigned int)operatorType]
                                         userInfo:nil];
            break;
    }
}

- (NSString *)nameWithCompoundPredicateType:(NSCompoundPredicateType)predicateType
{
    switch (predicateType) {
        case NSAndPredicateType:
            return @"and";
        case NSOrPredicateType:
            return @"or";
        case NSNotPredicateType:
            return @"not";
        default:
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Given NSCompoundPredicateType `%u` is not supported.", (unsigned int)predicateType]
                                         userInfo:nil];
            break;
    }
}

- (id)objectWithExpression:(NSExpression *)expression
{
    switch (expression.expressionType) {
        case NSKeyPathExpressionType:
            return @{
                     ODDataSerializationCustomTypeKey: @"keypath",
                     @"$val": expression.keyPath,
                     };
        case NSConstantValueExpressionType:
            return [ODDataSerialization serializeObject:expression.constantValue];
        default:
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Given NSExpressionType `%u` is not supported.", (unsigned int)expression.expressionType]
                                         userInfo:nil];
            break;
    }
}

- (NSArray *)arrayWithPredicate:(NSPredicate *)predicate
{
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate *comparison = (NSComparisonPredicate *)predicate;
        return @[[self nameWithPredicateOperatorType:[comparison predicateOperatorType]],
                 [self objectWithExpression:[comparison leftExpression]],
                 [self objectWithExpression:[comparison rightExpression]],
                 ];
    } else if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *compound = (NSCompoundPredicate *)predicate;
        NSMutableArray *result = [NSMutableArray arrayWithObject:[self nameWithCompoundPredicateType:compound.compoundPredicateType]];
        [[compound subpredicates] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [result addObject:[self arrayWithPredicate:(NSPredicate *)obj]];
        }];
        return [result copy];
    } else if (!predicate) {
        return [NSArray array];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"The given predicate is neither a NSComparisonPredicate or NSCompoundPredicate. Given: %@", NSStringFromClass([predicate class])]
                                     userInfo:nil];
    }
}

@end
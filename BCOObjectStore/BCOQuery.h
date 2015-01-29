//
//  BCOQuery.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 25/01/2015.
//
//

#import <Foundation/Foundation.h>



typedef NS_ENUM(NSInteger, BCOQueryOperator) {
    BCOQueryOperatorInvalid = -1,

    BCOQueryOperatorEqualTo,
    BCOQueryOperatorIn,
    BCOQueryOperatorLessThan,
    BCOQueryOperatorLessThanOrEqualTo,
    BCOQueryOperatorGreaterThan,
    BCOQueryOperatorGreaterThanOrEqualTo,
    BCOQueryOperatorNotEqualTo,
    BCOQueryOperatorPredicate,
};



@interface BCOWhereClauseExpression : NSObject
@property(nonatomic, readonly) BCOQueryOperator operator;
@property(nonatomic, readonly) NSString *indexName; //TODO: Rename to leftOperand
@property(nonatomic, readonly) id value; //TODO: Rename to rightOperand
@end



@interface BCOQuery : NSObject
+(BCOQuery *)queryFromString:(NSString *)queryString substitutionVariables:(NSDictionary *)subsitutionVariable;
@property(nonatomic, readonly) NSArray *whereClauseExpressions;
@property(nonatomic, readonly) NSArray *sortDescriptors;
@end

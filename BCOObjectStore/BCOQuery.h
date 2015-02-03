//
//  BCOQuery.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 25/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOWhereClauseExpression;



typedef NS_ENUM(NSInteger, BCOQueryOperator) {
    BCOQueryOperatorInvalid = -1,

    BCOQueryOperatorEqualTo,
    BCOQueryOperatorNotEqualTo,

    BCOQueryOperatorIn,
    BCOQueryOperatorNotIn,

    BCOQueryOperatorLessThan,
    BCOQueryOperatorLessThanOrEqualTo,
    BCOQueryOperatorGreaterThan,
    BCOQueryOperatorGreaterThanOrEqualTo,

    BCOQueryOperatorPredicate,

    BCOQueryOperatorAND,
    BCOQueryOperatorOR,
};



@interface BCOQuery : NSObject
+(BCOQuery *)queryFromString:(NSString *)queryString substitutionVariables:(NSDictionary *)subsitutionVariable;


// TODO: Allow agregation/mapping functions for select field
@property(nonatomic, readonly) NSString *selectField;
@property(nonatomic, readonly) BCOWhereClauseExpression *rootWhereExpression;
@property(nonatomic, readonly) NSString *groupBy;
@property(nonatomic, readonly) NSArray *sortDescriptors;
@end



@interface BCOWhereClauseExpression : NSObject
@property(nonatomic, readonly) BCOQueryOperator operator;
@property(nonatomic, readonly) id leftOperand;
@property(nonatomic, readonly) id rightOperand;
@end



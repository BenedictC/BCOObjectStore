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

//TODO: EG: 'SELECT * FROM masterTable', 'SELECT name FROM indexName'
// The 'SELECT *' could translate to a KVC-inspired keypath. 'SELECT name, date' , 'SELECT @sum/avg/max/min(numberProperty)', @distinct(), @union() 
//TODO: what's the difference between specifying a restriction in a FROM clause compared to in the WHERE clause?
//@property(nonatomic, readonly) id *selectClause;

@property(nonatomic, readonly) BCOWhereClauseExpression *rootWhereExpression;

@property(nonatomic, readonly) NSArray *sortDescriptors;
@end




@interface BCOWhereClauseExpression : NSObject
@property(nonatomic, readonly) BCOQueryOperator operator;
@property(nonatomic, readonly) id leftOperand;
@property(nonatomic, readonly) id rightOperand;
@end



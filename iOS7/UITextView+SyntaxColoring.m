//
//  NSTextView+SyntaxColoring.m
//  RuntimeBrowser
//
//  Created by Nicolas Seriot on 04.08.08.
//  Copyright 2008 seriot.ch. All rights reserved.
//

// written and optimized for runtime browser

#import "UITextView+SyntaxColoring.h"
#import "NSMutableAttributedString+RTB.h"

#define isAZaz_(c) ( (c >= 'A' && c <= 'z') || c == '_' )

@implementation UITextView (SyntaxColoring)

char **stringArrayFromNSArray(NSArray *a) {
	NSUInteger count = [a count];
	NSUInteger maxLength = [[a objectAtIndex:0] length]; // because a is supposed to be sorted by length, order desc
	NSUInteger i;
	
	char **sa = malloc(count*maxLength*sizeof(unichar));
	for(i = 0; i < count; i++) {
		sa[i] = (char *)[[a objectAtIndex:i] cStringUsingEncoding:NSUTF8StringEncoding];
	}
	return sa;
}

- (void)tryToColorizeWithTokens:(char **)tokens
					   nbTokens:(NSUInteger)nbTokens
							ptr:(char *)ptr
						   text:(const char*)text
				   firstCharSet:(NSCharacterSet *)cs1
				  secondCharSet:(NSCharacterSet *)cs2
						  color:(UIColor *)color
               attributedString:(NSMutableAttributedString *)mas {
	NSUInteger tokenLength;
	NSUInteger i;
	if([cs1 characterIsMember:*ptr] && [cs2 characterIsMember:*(ptr+1)]) {
		for(i = 0; i < nbTokens; i++) {
			tokenLength = strlen(tokens[i]); // TODO: optimize here: strlen is called 378185 times for NSObject...
			if(!isAZaz_(*(ptr+tokenLength)) && !strncmp(tokens[i], ptr, tokenLength)) {
				[mas setTextColor:color range:NSMakeRange(ptr-text, tokenLength)];
				ptr += tokenLength;
				break;
			}
		}
	}
}

- (void)colorizeWithKeywords:(NSArray *)keywords classes:(NSArray *)classes {

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[self text]];

#ifdef DEBUG
	double start = [[NSDate date] timeIntervalSince1970];
#endif
	
	const char* text = [[self text] cStringUsingEncoding:NSUTF8StringEncoding];
	char *tmp = (char *)text;

	UIColor *commentsColor = [UIColor colorWithRed:0.0 green:119.0/255 blue:0.0 alpha:1.0];
	UIColor *keywordsColor = [UIColor colorWithRed:193.0/255 green:0.0 blue:145./255 alpha:1.0];
	UIColor *classesColor = [UIColor colorWithRed:103.0/255 green:31.0/255 blue:155./255 alpha:1.0];
	//NSColor *typesColor = [NSColor colorWithCalibratedRed:53.0/255 green:0.0/255 blue:111./255 alpha:1.0];
	
	NSMutableCharacterSet *kwCS1 = [[NSMutableCharacterSet alloc] init];
	NSMutableCharacterSet *kwCS2 = [[NSMutableCharacterSet alloc] init];
	NSMutableCharacterSet *clCS1 = [[NSMutableCharacterSet alloc] init];
	NSMutableCharacterSet *clCS2 = [[NSMutableCharacterSet alloc] init];
	
	for(NSString *k in keywords) {
		[kwCS1 addCharactersInString:[k substringWithRange:NSMakeRange(0, 1)]];
		[kwCS2 addCharactersInString:[k substringWithRange:NSMakeRange(1, 1)]];
	}

	for(NSString *c in classes) {
		[clCS1 addCharactersInString:[c substringWithRange:NSMakeRange(0, 1)]];
		[clCS2 addCharactersInString:[c substringWithRange:NSMakeRange(1, 1)]];
	}
	
	// we use char** to avoid numerous -cString calls on the same NSStrings	
	NSUInteger kwCount = [keywords count];
	NSUInteger clCount = [classes count];

	NSUInteger colorStart;
	NSUInteger colorStop;

	char **kw = stringArrayFromNSArray(keywords);
	char **cl = stringArrayFromNSArray(classes);
	
	while(*tmp != '\0') {
		
		// color comments
		if(*tmp == '/' && *(tmp+1) == '*') {
			colorStart = tmp-text;
			do {
				tmp++; 
			} while(*tmp != '\0' && *(tmp+1) != '\0' && !(*tmp == '*' && *(tmp+1) == '/'));
			colorStop = tmp-text+2;
			[attributedString setTextColor:commentsColor range:NSMakeRange(colorStart, colorStop-colorStart)];
		}
		
		// color directives
		if(*tmp == '@') {
			colorStart = tmp-text;
			do {
				tmp++;
			} while(*tmp != '\0' && *tmp != ' ' && *tmp != '(' && *tmp != '\n');
			colorStop = tmp-text;
			[attributedString setTextColor:keywordsColor range:NSMakeRange(colorStart, colorStop-colorStart)]; // we use kwColor also for directives
		}
		
		// color keywords
		if( !isAZaz_(*tmp) ) {
			tmp++;
			if(*tmp == '\0') {
				free(kw); free(cl);
#ifdef DEBUG
				NSLog(@"-- colored in %f seconds", [[NSDate date] timeIntervalSince1970] - start);
#endif
                
                self.attributedText = attributedString;

				return;
			}

			[self tryToColorizeWithTokens:kw nbTokens:kwCount ptr:tmp text:text firstCharSet:kwCS1 secondCharSet:kwCS2 color:keywordsColor attributedString:attributedString];
			[self tryToColorizeWithTokens:cl nbTokens:clCount ptr:tmp text:text firstCharSet:clCS1 secondCharSet:clCS2 color:classesColor attributedString:attributedString];
			
		} else {
			tmp++;
		}
		
	}

	free(kw); free(cl);

#ifdef DEBUG
	NSLog(@"-- colored in %f seconds", [[NSDate date] timeIntervalSince1970] - start);
#endif
    
    self.attributedText = attributedString;
}

@end

//
//  EditImageViewController.m
//  WriteOff
//
//  Created by Mike Miller on 7/7/12.
//  Copyright (c) 2012 Mike Miller. All rights reserved.
//

#import "EditImageViewController.h"

#import "ImageCropCell.h"
#import "CroppableImage.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/ALAssetRepresentation.h>
#import "UIImage+normalize.h"
#import "Settings.h"
#import "ImageManager.h"
#import "EditableCell.h"

@implementation EditImageViewController

@synthesize uploadableImage;

#pragma mark - ImageCropViewControllerDelegate

- (void)imageCropViewControllerDidCancel:(ImageCropViewController *)controller
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateUI {
    [self.tableView reloadData];
}

- (void)imageCropViewControllerDidSave:(ImageCropViewController *)controller
{
	[self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"crop view saved, getting cropped image");
    //UploadableImage *image = [UploadableImage imageWithCGImage:[[controller getCroppedImage] CGImage]];
    //[_images addObject:image];
    [self updateUI];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"prepareForSegue");
	if ([segue.identifier isEqualToString:@"CropImage"])
	{
        NSInteger row = ((UIButton *)sender).tag;
        CroppableImage *croppableImage = [uploadableImage.croppableImages objectAtIndex:row];

        NSLog(@"Preparing for CropImage segue from row %i!", row);
        ImageCropViewController *imageCropViewController = segue.destinationViewController;
        imageCropViewController.delegate = self;
        if (croppableImage) {
            NSLog(@"valid image in prepareForSegue, so setting on imageCropViewController");
            imageCropViewController.croppableImage = croppableImage;
        } else {
        NSLog(@"INVALID IMAGE in prepareForSegue");
        }
	}
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Images";
    } else {
        return @"Merge Images";
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return uploadableImage.croppableImages.count + 1;
    } else {
        return 2;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row < uploadableImage.croppableImages.count) {
            static NSString *CellIdentifier = @"ImageCropCell";
            ImageCropCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[ImageCropCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            CroppableImage *croppableImage =  [uploadableImage.croppableImages objectAtIndex:indexPath.row];
            cell.imageView.image = croppableImage.croppedImage;
            cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
            
            cell.cropButton.tag = indexPath.row;
            
            return cell;
        } else {
            static NSString *CellIdentifier = @"AppendImageCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
            backView.backgroundColor = [UIColor clearColor];
            cell.backgroundView = backView;
            return cell;
        }
    } else if (indexPath.section == 1) {
        static NSString *CellIdentifier = @"MergeImagesCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Left to Right";
            if (uploadableImage.imageMergeStyle == ImageMergeStyleLeftToRight) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            } else {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        } else {
            cell.textLabel.text = @"Top to Bottom";
            if (uploadableImage.imageMergeStyle == ImageMergeStyleTopToBottom) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            } else {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    } else if (indexPath.section == 2) {
        static NSString *CellIdentifier = @"NameCell";
        EditableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[EditableCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
        }
        
        SpreadsheetManager *spreadsheetManager = self.uploadableImage.spreadsheetManager;
        
        cell.textLabel.text = [[spreadsheetManager.headerToValueMap objectAtIndex:indexPath.row] objectAtIndex:0];
        cell.textField.placeholder = cell.textLabel.text;
        
        NSString *valueText = [[spreadsheetManager.headerToValueMap objectAtIndex:indexPath.row] objectAtIndex:1];
        /*if (valueText == @"DEBUG_TEXT") {
         //mikem: remove this if block and always do the else.
         cell.textField.text = [@"Test " stringByAppendingString:cell.textLabel.text];
         NSMutableArray *headerToValue = [spreadsheetManager.headerToValueMap objectAtIndex:indexPath.row];
         [headerToValue removeObjectAtIndex:1];
         //NSLog(@"Test added string %@ value to header %@", cell.textField.text, [headerToValue objectAtIndex:0]);
         [headerToValue addObject:cell.textField.text];
         } else */{
             //NSLog(@"Setting text to stored text: %@", valueText);
             cell.textField.text = valueText;
         }
        
        
        cell.textField.delegate = self;
        
        if (cell.textLabel.text == @"Price" || cell.textLabel.text == @"Cost" || cell.textLabel.text == @"Total") {
            [cell.textField setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
        } else {
            [cell.textField setKeyboardType:UIKeyboardTypeAlphabet];
        }
        
        if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
            [cell.textField setReturnKeyType:UIReturnKeyDone];
        } else {
            [cell.textField setReturnKeyType:UIReturnKeyNext];
        }
        
        cell.textField.tag = indexPath.row;
        return cell;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        // Image rows get a fixed height
        if (indexPath.row < uploadableImage.croppableImages.count) {
            return 84;
        } else {
            return 64;
        }
    } else if (indexPath.section == 1) {
        // Merge images row
        return 48;
    }
    
    return 10;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        uploadableImage.imageMergeStyle = indexPath.row == 0 ? ImageMergeStyleLeftToRight : ImageMergeStyleTopToBottom;
        [self updateUI];
        /*
        NSUInteger thisIndex = [[tableView indexPathsForVisibleRows] indexOfObject:indexPath];
        if (thisIndex != NSNotFound) {
            UITableViewCell *cell = [[tableView visibleCells] objectAtIndex:thisIndex];
            
            //[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        }*/
        /*
        // Deselect the other row
        NSIndexPath *otherIndexPath = [NSIndexPath indexPathForRow:indexPath.row == 0 ? 1 : 0 inSection:1];
        
        NSUInteger otherIndex = [[tableView indexPathsForVisibleRows] indexOfObject:otherIndexPath];
        if (otherIndex != NSNotFound) {
            UITableViewCell *cell = [[tableView visibleCells] objectAtIndex:otherIndex];
            
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }*/
    }
}

- (void)editRow:(NSInteger)row
{
    /*
    [self.view endEditing:YES];
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    EditableCell *cell = (EditableCell*)[self.tableView cellForRowAtIndexPath:path];    
    NSLog(@"Editing row %d", row);
    NSLog(@"  row text: %@", cell.textLabel.text);
    
    
    if([cell.textField becomeFirstResponder]) {
        NSLog(@"Became first responder");
    } else {
        NSLog(@"Could not become first responder");
    }*/
}

- (IBAction)cropButtonPressed:(id)sender {
    NSInteger row = ((UIButton *)sender).tag;
    NSLog(@"The row id is %i",  row); 
}




- (void) useCamera
{    
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera])
    {
        NSLog(@"Popping up camera");
        UIImagePickerController *imagePicker =
        [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = 
        UIImagePickerControllerSourceTypeCamera;
        imagePicker.mediaTypes = [NSArray arrayWithObjects:
                                  (NSString *) kUTTypeImage,
                                  nil];
        imagePicker.allowsEditing = NO;
        [self presentModalViewController:imagePicker 
                                animated:YES];
    }
}

- (void) useCameraRoll
{
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeSavedPhotosAlbum])
    {
        UIImagePickerController *imagePicker =
        [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = 
        UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes = [NSArray arrayWithObjects:
                                  (NSString *) kUTTypeImage,
                                  nil];
        imagePicker.allowsEditing = NO;
        [self presentModalViewController:imagePicker animated:YES];
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info
                           objectForKey:UIImagePickerControllerMediaType];
    
    //[self dismissModalViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:^() {
        NSLog(@"Completed dismissing camera view.");
    }];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        
        NSLog(@"Took picture. Getting rotated image.");
        
        UIImage *image = [[info 
                           objectForKey:UIImagePickerControllerOriginalImage] rotated];
        
        int newLargestDimension = [Settings instance].maximumSourceImageLongestDimension;
        NSLog(@"newLargestDimension: %i", newLargestDimension);
        
        UIImage *resizedImage = [ImageManager makeResizedImage:image withNewLargestDimension:newLargestDimension andQuality:kCGInterpolationHigh];
        
        [self.uploadableImage addCroppableImage:[CroppableImage croppableImageWithImage:resizedImage]];
        [self updateUI];
        
        // Scroll to the newly added image
        //CGPoint bottomOffset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height);
        //[self.tableView setContentOffset:bottomOffset animated:YES];
        
    }
}


-(void)image:(UIImage *)image
finishedSavingWithError:(NSError *)error 
 contextInfo:(void *)contextInfo
{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Save failed"
                              message: @"Failed to save image"\
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
}


@end

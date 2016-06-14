#import "CMHObjectUtilities.h"

bool cmhAreObjectsEqual(id o1, id o2) {
    if (o1 == o2) {
        return true;
    }

    if (nil == o1 ||  nil == o2) {
        return false;
    }

    return [o1 isEqual:o2];
}

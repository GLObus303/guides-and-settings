# Bug reporting

_The ultimate guide for smart bug reporting that helps everyone_

1. The bug has to be consistently reproducible
2. Create a description that is concise and laconic
3. Screenshots of a console, bug itself, and any special setup will greatly improve the explanation

## Bug report example

### Save button on the item detail page is not working

- **Operating system:** OS X
- **Browser:** Chrome 70 (no need for more specific versioning)
- **Environment:** Production
- **Url:** https://www.foo.com/bar/545

**Description:** Button fails after trying to apply any changes to the item.

**Steps to reproduce:**

1. Open item detail page
2. Click edit item button
3. Make changes to the item (e.g. change its title)
4. Click `Save` button
5. **Nothing happens, error 500 is thrown in the notifications (see Screenshot 1) and in the console (see Screenshot 2)**

Screenshot 1:

![Notification error](https://pasteboard.co/JKQWEsV.png)

Screnshot 2:

![Console error](https://pasteboard.co/JKQWX00.png)

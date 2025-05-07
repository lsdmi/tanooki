const initializeTinymce = () => {
  const textarea = document.querySelector('.tinymce');
  if (!textarea) return;

  const textareaIframe = document.querySelector('.tox-tinymce');
  if (textareaIframe) textareaIframe.remove();

  tinymce.remove();
  tinymce.util.I18n.add('uk', {
    'Align': 'Вирівнювання',
    'Advanced': 'Додатково',
    'Alternative description': 'Опис',
    'Alternative source URL': 'Альтернативний URL',
    'Background color': 'Колір тла',
    'Blockquote': 'Цитата',
    'Bold': 'Жирний',
    'Cancel': 'Відмінити',
    'Center': 'По центру',
    'Characters (no spaces)': 'Символів (без пробілів)',
    'Characters': 'Символів (всього)',
    'Clear formatting': 'Очистити форматування',
    'Close': 'Вийти',
    'Code': 'Код',
    'Color picker': 'Вибір кольору',
    'Count': 'Кількість',
    'Current window': 'Поточне вікно',
    'Decrease indent': 'Зменшити відступ',
    'Document': 'Документ',
    'Embed': 'Вставити',
    'Fonts': 'Шрифти',
    'Font sizes': 'Розмір шрифту',
    'General': 'Загальне',
    'Height': 'Висота',
    'Horizontal line': 'Горизонтальна лінія',
    'Increase indent': 'Збільшити відступ',
    'Insert/edit image': 'Вставити/редагувати зображення',
    'Insert/edit media': 'Вставити/редагувати медіа',
    'Insert/edit link': 'Вставити/редагувати посилання',
    'Italic': 'Курсив',
    'Justify': 'По ширині',
    'Left': 'Ліворуч',
    'Line height': 'Висота рядка',
    'Link': 'Посилання',
    'Media poster (Image URL)': 'Постер (URL зображення)',
    'New window': 'Нове вікно',
    'Open link in...': 'Відкрити посилання в...',
    'Paste your embed code below:': 'Вставте код нижче:',
    'Redo': 'Повторити',
    'Right': 'Праворуч',
    'Save': 'Зберегти',
    'Selection': 'Виділене',
    'Source': 'Джерело',
    'Source code': 'Вихідний код',
    'System Font': 'Шрифт',
    'Text to display': 'Текст для відображення',
    'Underline': 'Підкреслення',
    'Undo': 'Відмінити',
    'Width': 'Ширина',
    'Word count': 'Кількість слів',
    'Words': 'Слів'
  });
  tinymce.init({
    language: 'uk',
    selector: 'textarea',
    height: 500,
    plugins: [
      'autosave',
      'code',
      'image',
      'link',
      'lists',
      'media',
      'quickbars',
      'wordcount'
    ],
    menubar: false,
    toolbar: 'undo redo | bold italic underline | link | fontfamily fontsize align lineheight | backcolor | removeformat | outdent indent | image media | hr | code | wordcount',
    quickbars_insert_toolbar: 'image media',
    quickbars_selection_toolbar: 'bold italic underline | blockquote quicklink',
    contextmenu: false,
    statusbar: false,
    newline_behavior: 'linebreak',
    link_title: false
  });
};

document.addEventListener('turbo:load', initializeTinymce);
document.addEventListener('turbo:render', initializeTinymce);

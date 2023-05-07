const initializeTinymce = () => {
  const textarea = document.querySelector('.tinymce');
  if (!textarea) return;

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
    'Clear formatting': 'Очистити форматування',
    'Code': 'Код',
    'Color picker': 'Вибір кольору',
    'Decrease indent': 'Зменшити відступ',
    'Embed': 'Вставити',
    'Fonts': 'Шрифти',
    'Font sizes': 'Розмір шрифту',
    'General': 'Загальне',
    'Height': 'Висота',
    'Horizontal line': 'Горизонтальна лінія',
    'Increase indent': 'Збільшити відступ',
    'Insert/edit image': 'Вставити/редагувати зображення',
    'Insert/edit media': 'Вставити/редагувати медіа',
    'Italic': 'Курсив',
    'Justify': 'По ширині',
    'Left': 'Ліворуч',
    'Line height': 'Висота рядка',
    'Link': 'Посилання',
    'Media poster (Image URL)': 'Постер (URL зображення)',
    'Paste your embed code below:': 'Вставте код нижче:',
    'Redo': 'Повторити',
    'Right': 'Праворуч',
    'Save': 'Зберегти',
    'Source': 'Джерело',
    'Source code': 'Вихідний код',
    'System Font': 'Шрифт',
    'Text color': 'Колір тексту',
    'Underline': 'Підкреслення',
    'Undo': 'Відмінити',
    'Width': 'Ширина',
    'Word count': 'Кількість слів'
  });
  tinymce.init({
    language: 'uk',
    selector: 'textarea',
    height: 500,
    plugins: [
      'code',
      'image',
      'link',
      'lists',
      'media',
      'quickbars'
    ],
    menubar: false,
    toolbar: 'undo redo | bold italic underline | fontfamily fontsize align lineheight | forecolor backcolor | removeformat | outdent indent | image media | hr | code',
    quickbars_insert_toolbar: 'image media',
    quickbars_selection_toolbar: 'bold italic underline | blockquote quicklink',
    statusbar: false,
    newline_behavior: 'linebreak'
  });
};

document.addEventListener('turbo:load', initializeTinymce);
document.addEventListener('turbo:render', initializeTinymce);

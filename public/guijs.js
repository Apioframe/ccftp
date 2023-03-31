function toast(title, body) {
  // get existing toasts
  const toasts = document.querySelectorAll('.toast');
  const numToasts = toasts.length;

  // create new toast
  const toast = document.createElement('div');
  toast.classList.add('ui');
  toast.classList.add('toast');
  toast.style.bottom = `${20 + numToasts * (toast.offsetHeight + 20)}px`;

  const toastHeader = document.createElement('div');
  toastHeader.classList.add('ui');
  toastHeader.classList.add('toast-header');

  const toastTitle = document.createElement('div');
  toastTitle.classList.add('ui');
  toastTitle.classList.add('toast-title');
  toastTitle.innerText = title;

  const close = document.createElement('button');
  close.classList.add('ui');
  close.classList.add('close');
  close.innerHTML = '&times;';
  close.addEventListener('click', () => toast.remove());

  toastHeader.appendChild(toastTitle);
  toastHeader.appendChild(close);
  toast.appendChild(toastHeader);

  const toastBody = document.createElement('div');
  toastBody.classList.add('ui');
  toastBody.classList.add('toast-body');
  toastBody.innerText = body;

  toast.appendChild(toastBody);

  // add progress bar to toast
  const progressBar = document.createElement('div');
  progressBar.classList.add('ui');
  progressBar.classList.add('progress-bar');
  toast.appendChild(progressBar);

  // add new toast to document
  document.body.appendChild(toast);

  // animate progress bar
  let progress = 0;
  const intervalId = setInterval(() => {
    progress += 1;
    progressBar.style.width = `${progress}%`;
    if (progress === 100) {
      clearInterval(intervalId);
      toast.remove();

      // update bottom position of remaining toasts
      const remainingToasts = document.querySelectorAll('.toast');
      remainingToasts.forEach((t, i) => {
        t.style.bottom = `${20 + i * (toast.offsetHeight + 20)}px`;
      });
    }
  }, 50);
}
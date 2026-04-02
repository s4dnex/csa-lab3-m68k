# Лабораторная работа №3 (m86k)

> Вариант: **base64_encoding**
> 
<!-- > > [Wrench Simulation Report](link here) -->

```python
def base64_encoding(input):
    """Encode input string to base64.

    - Result string should be represented as a correct C string.
    - Buffer size for the encoded message -- `0x40`, starts from `0x00`.
    - End of input -- new line.

    Python example args:
        input (str): The input string containing data to encode.

    Returns:
        tuple: A tuple containing the base64 encoded string and the remaining input.
    """
    line, rest = read_line(input, 0x40)
    if line is None:
        return [overflow_error_value], rest

    encoded_bytes = base64.b64encode(line.encode("utf-8"))
    encoded_str = encoded_bytes.decode("ascii")

    if len(encoded_str) + 1 > 0x40:  # +1 for null terminator
        return [overflow_error_value], rest

    return cstr(encoded_str, 0x40)[0], rest


assert base64_encoding('Hello!\n') == ('SGVsbG8h', '')
```

1. Реализация заданных вариантом алгоритмов на заданных архитектурах (см. документацию [Wrench](https://github.com/ryukzak/wrench)):
   - аккумуляторная архитектура `acc32`
   - CISC архитектура `m68k`
   - стековая архитектура `f32a`
   - RISC архитектура `risc-iv-32`
 
2. Подготовка принципиальной схемы заданной вариантом для одного из используемых процессоров.

3. Защита реализованных алгоритмов (включая понимание архитектуры процессора, её достоинств и недостатков) и схемы.


Ваш вариант будет приведён в ведомости. Расшифровка варианта приведена в файле: [variants.md](https://github.com/ryukzak/wrench/blob/master/variants.md), где приведён код на языке Python и набор тестов. Вам необходимо написать эквивалентные алгоритмы на заданной архитектуре с учётом следующих требований:

1. Если ввод не соответствует области определения -- вернуть `-1`.

2. Если результат не может быть корректно рассчитан (результат не может быть представлен в рамках машинного слова) -- вернуть результат заполненный байтами со значениями `0xCC`.

3. Ввод должен подаваться через ячейку памяти `0x80`.

4. Вывод должен подаваться в ячейку памяти `0x84`.

5. Входное значение и результат по умолчанию — машинное слово в 32 бита, если не указано иное.

6. Исходный код должен быть отформатирован (вручную или при помощи `wrench-fmt`).

7. Журнал работы не должен быть обрезан (используйте конфигурацию с пониманием).

8. Требования, специфичные для ISA:
    - `f32a`: использовать процедуры;
    - `risc-iv-32`: использовать вложенных процедур[^1], с целью демонстрации работы со стеком. Где применимо -- рекомендуется рекурсивное решение задачи.
    - `m68k`: необходимо использовать различные режимы инструкций и способы адресации. Использовать вложенные процедуры и стек.

9. При использовании процедур требуется выработать способ именования меток, помогающий видеть структуру кода.
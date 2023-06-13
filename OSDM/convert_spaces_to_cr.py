

if __name__ == '__main__':

    words_in = open("words_in.txt", "r")
    words_list_file = open("words_list.txt", "w+")
    words_list_full_file = open("words_list_full.txt", "w+")

    all_words = words_in.read().split(" ")

    uniques = list(set(all_words))
    
    words_list_cr = "\n".join(all_words)
    uniques_cr = "\n".join(uniques)

    words_list_file.write(uniques_cr)
    words_list_full_file.write(words_list_cr)

    words_in.close()
    words_list_file.close()
    words_list_full_file.close()